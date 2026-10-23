//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import Charts

fileprivate let heartColor = Color.pink
fileprivate let darkHeartColor = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.369, green: 0.090, blue: 0.145, alpha: 1) : UIColor(red: 0.973, green: 0.792, blue: 0.835, alpha: 1) }) // Dark pink, light pink in light mode

struct HeartChartDataPoint: Identifiable, Equatable {
    var id: Date { date } // Stable across refetches so bars don't flicker when the buffer reloads
    let date: Date
    let min: Double
    let max: Double
    let average: Double
    let median: Double
    let values: [Double]
}

struct HeartChartView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("heartPointMarkMode") private var heartPointMarkMode = "average"
    
    @State private var points = [HeartChartDataPoint]()
    @State private var loadedRange: DateInterval?
    @State private var firstReadingDate: Date?
    @State private var scrollPositionDate = Calendar.current.startOfDay(for: Date())
    @State private var rawSelectedHour: Date? = nil
    @State private var displayedMin = NotificationSettingsManager.shared.settings.heartSettings.minRange
    @State private var displayedMax = NotificationSettingsManager.shared.settings.heartSettings.maxRange
    @State private var yDomain = NotificationSettingsManager.shared.settings.heartSettings.minRange...NotificationSettingsManager.shared.settings.heartSettings.maxRange
    @State private var pendingYScaleUpdate: DispatchWorkItem?
    @State private var snapAnimation: Task<Void, Never>?
    @State private var scrollFetch: Task<Void, Never>?
    @State private var lastSnapWrite: Date?
    
    private let cal = Calendar.current
    private let visibleDomain: TimeInterval = 86400
    private let bufferDays = 2 // Days kept loaded either side of the visible day
    
    var visiblePoints: [HeartChartDataPoint] {
        let visibleEnd = Date(timeInterval: visibleDomain, since: scrollPositionDate)
        return points.filter { $0.date >= scrollPositionDate && $0.date <= visibleEnd }
    }
    // Axis marks only for loaded days, so the chart doesn't lay out marks across the whole history
    var axisDates: [Date] {
        guard let loadedRange else { return [] }
        
        var dates = [Date]()
        var day = loadedRange.start
        while day < loadedRange.end {
            dates += [0, 6, 12, 18].compactMap { cal.date(bySettingHour: $0, minute: 0, second: 0, of: day) }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return dates + [loadedRange.end]
    }
    var latestDate: Date {
        points.map({ $0.date }).max() ?? Date()
    }
    var selectedViewHour: HeartChartDataPoint? {
        guard let rawSelectedHour else { return nil }
        return points.first {
            cal.isDate(rawSelectedHour, equalTo: $0.date, toGranularity: .hour)
        }
    }
    var pointMarkLabel: String {
        heartPointMarkMode == "average" ? NSLocalizedString("avg", comment: "") : NSLocalizedString("mdn", comment: "")
    }
    private var bpmText: String {
        if let selectedViewHour {
            return isSingleReading(selectedViewHour)
            ? "\(Int(selectedViewHour.min))"
            : "\(Int(selectedViewHour.min))–\(Int(selectedViewHour.max))"
        }
        
        return visiblePoints.isEmpty ? "--" : "\(displayedMin)–\(displayedMax)"
    }
    
    private var detailText: String {
        if let selectedViewHour {
            let rangeFirstHour =
            cal.dateInterval(of: .hour, for: selectedViewHour.date)?.start
            ?? selectedViewHour.date
            
            let rangeLastHour =
            cal.date(byAdding: .hour, value: 1, to: rangeFirstHour)
            ?? rangeFirstHour
            
            let readings = selectedViewHour.values.count
            // Keep 23–00 on the same day instead of showing the next date for midnight to avoid a line break
            let hours = cal.isDate(rangeFirstHour, inSameDayAs: rangeLastHour)
            ? (rangeFirstHour..<rangeLastHour).formatted(.interval.month(.abbreviated).day().hour())
            : rangeFirstHour.formatted(.dateTime.month(.abbreviated).day()) + ", " + rangeFirstHour.formatted(.dateTime.hour()) + " – " + rangeLastHour.formatted(.dateTime.hour())
            let average = readings > 1 ? " · " + String(localized: "\(Int(pointMarkValue(for: selectedViewHour))) BPM \(pointMarkLabel)") : ""
            
            return "\(hours) · " + String(localized: "\(readings) readings") + average
        }
        
        let rounded = Date(timeIntervalSinceReferenceDate: (scrollPositionDate.timeIntervalSinceReferenceDate / 3600).rounded() * 3600)
        
        let end = Date(timeInterval: visibleDomain, since: rounded)
        let isFullDay = cal.component(.hour, from: rounded) == 0
        
        return isFullDay
        ? rounded.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
        : (rounded..<end).formatted(.interval.month(.abbreviated).day().hour().minute())
    }
    
    func pointMarkValue(for point: HeartChartDataPoint) -> Double {
        heartPointMarkMode == "average" ? point.average : point.median
    }
    
    func updateYScale() {
        let heartSettings = NotificationSettingsManager.shared.settings.heartSettings
        
        displayedMin = Int(visiblePoints.map({ $0.min }).min() ?? Double(heartSettings.minRange))
        displayedMax = Int(visiblePoints.map({ $0.max }).max() ?? Double(heartSettings.maxRange))
        
        // Round readings out to the axis label step so the top and bottom of the chart land on a label
        yDomain = visiblePoints.isEmpty
            ? displayedMin...displayedMax
            : (displayedMin - 5) / 25 * 25...((displayedMax + 5 + 24) / 25 * 25)
    }
    
    func nearestHour(to date: Date) -> Date {
        let hourStart = cal.dateInterval(of: .hour, for: date)?.start ?? date
        
        return date.timeIntervalSince(hourStart) < 1800 ? hourStart : hourStart.addingTimeInterval(3600)
    }
    
    // The chart ignores withAnimation for scroll position changes, so step it manually
    // Is there a less hacky way to do this?
    func animateScroll(to target: Date) {
        let start = scrollPositionDate
        let distance = target.timeIntervalSince(start)
        let frames = 12

        snapAnimation?.cancel()
        snapAnimation = Task {
            for frame in 1...frames {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled else { return }

                let progress = Double(frame) / Double(frames)
                let next = start.addingTimeInterval(distance * (1 - pow(1 - progress, 3)))
                lastSnapWrite = next
                scrollPositionDate = next
            }
            lastSnapWrite = nil
        }
    }
    
    func scheduleYScaleUpdate() {
        pendingYScaleUpdate?.cancel()
        
        let update = DispatchWorkItem {
            let alignedDate = nearestHour(to: scrollPositionDate)
            
            if alignedDate != scrollPositionDate {
                animateScroll(to: alignedDate) // Re-fits the Y axis once the snap settles
            } else {
                withAnimation {
                    updateYScale()
                }
            }
        }
        pendingYScaleUpdate = update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: update)
    }
    
    // Load a few days either side of the date so neighbouring days are already populated when scrolled into
    func fetchPoints(around date: Date) async {
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -bufferDays, to: date)!)
        let end = cal.startOfDay(for: cal.date(byAdding: .day, value: bufferDays + 1, to: date)!)
        let predicate = NSPredicate(
            format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@",
            DeviceManager.shared.pairedDeviceID ?? "",
            start as NSDate,
            end as NSDate
        )
        loadedRange = DateInterval(start: start, end: end) // Set up front so scrolling doesn't start a fetch every frame
        
        let samples = await ChartManager.shared.heartRateSamples(predicate: predicate)
        let processed = await Task.detached { Self.process(samples) }.value
        guard !Task.isCancelled, processed != points else { return } // Skip if superseded by a newer fetch or nothing changed
        
        points = processed
    }
    
    // Pick up readings that arrived since the last fetch
    func refresh() async {
        let previousLatest = latestDate
        
        firstReadingDate = await ChartManager.shared.firstHeartRateDate()
        await fetchPoints(around: scrollPositionDate)
        
        // Follow the data onto a new day if the user was viewing the latest one
        if cal.isDate(scrollPositionDate, inSameDayAs: previousLatest), !cal.isDate(latestDate, inSameDayAs: previousLatest) {
            scrollPositionDate = cal.startOfDay(for: latestDate)
        }
        withAnimation {
            updateYScale()
        }
    }
    
    nonisolated static func process(_ samples: [HeartRateSample]) -> [HeartChartDataPoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: samples) { sample -> Date in
            let comps = cal.dateComponents([.year, .month, .day, .hour], from: sample.date)
            return cal.date(from: comps) ?? sample.date
        }
        
        return grouped
            .map { bucket, samples in
                let values = samples.map(\.value)
                
                return HeartChartDataPoint(
                    date: cal.date(byAdding: .minute, value: 30, to: bucket) ?? bucket,
                    min: values.min() ?? 0,
                    max: values.max() ?? 0,
                    average: values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count),
                    median: {
                        let sorted = values.sorted()
                        let mid = sorted.count / 2
                        return sorted.count % 2 == 0
                        ? (sorted[mid - 1] + sorted[mid]) / 2
                        : sorted[mid]
                    }(),
                    values: values
                )
            }
            .sorted { $0.date < $1.date }
    }
    
    func isSingleReading(_ point: HeartChartDataPoint) -> Bool {
        point.min == point.max
    }
    
    @ChartContentBuilder
    func chartContent(for point: HeartChartDataPoint, selected: HeartChartDataPoint?) -> some ChartContent {
        BarMark(
            x: .value("Time", point.date),
            yStart: .value("Min", point.min),
            yEnd: .value("Max", point.max),
            width: 7
        )
        .foregroundStyle(darkHeartColor)
        .cornerRadius(4)
        .opacity(selected == nil || selected?.date == point.date ? 1 : 0.35)
        
        PointMark(
            x: .value("Time", point.date),
            y: .value("BPM", pointMarkValue(for: point))
        )
        .foregroundStyle(heartColor)
        .symbolSize(CGSize(width: 7, height: 7))
        .symbol(.circle)
        .opacity(selected == nil || selected?.date == point.date ? 1 : 0.1)
    }
    
    func scrollButton(_ dir: Int, disabled: Bool) -> some View {
        Button {
            scrollPositionDate = cal.date(byAdding: .day, value: dir, to: scrollPositionDate)!
        } label: {
            Image(systemName: dir == 1 ? "chevron.right" : "chevron.left")
                .padding(12)
                .foregroundStyle(Color.primary)
                .fontWeight(.medium)
                .background(Material.regular)
                .clipShape(Circle())
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
    
    func chart(domain: ClosedRange<Date>) -> some View {
        Chart {
            if let selectedViewHour {
                RuleMark(x: .value("Selected Hour", selectedViewHour.date, unit: .hour))
                    .foregroundStyle(Color.gray)
            }
            ForEach(points) { point in
                chartContent(for: point, selected: selectedViewHour)
            }
        }
        .frame(minHeight: 280)
        .padding(.horizontal, 8)
        .chartYScale(domain: yDomain)
        .chartXScale(domain: domain)
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: Array(stride(from: 0, through: yDomain.upperBound, by: 25))) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    func chart() -> some View {
        let dayStart = cal.startOfDay(for: scrollPositionDate)
        
        return Group {
            if #available(iOS 17, *) {
                // Spans every day on record and doesn't move when the buffer reloads, so the scroll offset stays put
                let historyStart = cal.startOfDay(for: firstReadingDate ?? Date())
                let todayEnd = cal.startOfDay(for: Date()).addingTimeInterval(visibleDomain)
                
                chart(domain: historyStart...todayEnd)
                    .chartScrollableAxes(.horizontal)
                    .chartXVisibleDomain(length: visibleDomain)
                    .chartScrollPosition(x: $scrollPositionDate)
                    .chartScrollTargetBehavior(
                        .valueAligned(
                            matching: DateComponents(timeZone: .current, minute: 0, second: 0),
                            majorAlignment: .matching(DateComponents(timeZone: .current, hour: 0))
                        )
                    )
                    .chartXSelection(value: $rawSelectedHour)
            } else {
                chart(domain: dayStart...dayStart.addingTimeInterval(visibleDomain))
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let adjustedWidth = geo.size.width - 48
                                        let normalizedXPosition = min(max(value.location.x - 8, 0), adjustedWidth) / adjustedWidth
                                        rawSelectedHour = dayStart.addingTimeInterval(normalizedXPosition * visibleDomain)
                                    }
                                    .onEnded { _ in
                                        rawSelectedHour = nil
                                    }
                                )
                        }
                    )
            }
        }
    }
    
    private var notificationSummary: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        
        let parts: [(count: String, times: String, isSingle: Bool)] = [true, false].compactMap { low in
            let dates = NotificationManager.shared.heartRangeNotificationsToday(low: low)
            guard !dates.isEmpty else { return nil }
            
            let kind = low ? NSLocalizedString("low", comment: "") : NSLocalizedString("high", comment: "")
            let count = "\(formatter.string(from: NSNumber(value: dates.count)) ?? "\(dates.count)") \(kind)"
            let times = dates.map { $0.formatted(date: .omitted, time: .shortened) }
            return (count, dates.count <= 2 ? ", at " + times.joined(separator: " and ") : "", dates.count == 1)
        }
        guard let first = parts.first else { return nil }
        
        let firstCount = first.count.prefix(1).uppercased() + first.count.dropFirst()
        let noun = first.isSingle ? "heart rate notification was sent" : "heart rate notifications were sent"
        var summary = "\(firstCount) \(noun)\(first.times)"
        if parts.count > 1 {
            summary += ", and \(parts[1].count)\(parts[1].times)"
        }
        return summary + "."
    }
    
    var body: some View {
        Group {
            if firstReadingDate == nil {
                EmptyChartView(.heart)
            } else {
                Section {
                    chart()
                } header: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Group {
                                Text("\(bpmText) ")
                                    .font(.system(.title, design: .rounded))
                                    .foregroundColor(.primary)
                                + Text("BPM")
                            }
                            .contentTransition(.numericText())
                            Text(detailText)
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .fontWeight(.semibold)
                        if #unavailable(iOS 17), selectedViewHour == nil {
                            let dayStart = cal.startOfDay(for: scrollPositionDate)
                            
                            Spacer()
                            scrollButton(-1, disabled: dayStart <= cal.startOfDay(for: firstReadingDate ?? Date()))
                            scrollButton(1, disabled: dayStart >= cal.startOfDay(for: Date()))
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listRowBackground(Color.clear)
        .task {
            await refresh()
        }
        .onChange(of: scrollPositionDate) { newValue in
            // Any change the snap didn't write is the user scrolling, so stop the snap
            if let lastSnapWrite, abs(newValue.timeIntervalSince(lastSnapWrite)) > 1 {
                snapAnimation?.cancel()
                self.lastSnapWrite = nil
            }
            
            // Reload once the visible day reaches the outermost loaded day on either side
            if let loadedRange,
               newValue < loadedRange.start.addingTimeInterval(visibleDomain) ||
                newValue.addingTimeInterval(visibleDomain) > loadedRange.end.addingTimeInterval(-visibleDomain) {
                scrollFetch?.cancel()
                scrollFetch = Task {
                    await fetchPoints(around: newValue)
                    scheduleYScaleUpdate()
                }
            }
            scheduleYScaleUpdate()
        }
        .onReceive(BLEManager.shared.$heartRate.dropFirst().throttle(for: .seconds(30), scheduler: RunLoop.main, latest: true)) { _ in
            Task { await refresh() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await refresh() }
            }
        }
        .onChange(of: selectedViewHour?.date) { newValue in
            guard newValue != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if let notificationSummary {
            Section {
                Text(notificationSummary)
            }
        }
    }
}
