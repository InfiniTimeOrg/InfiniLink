//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import Charts

fileprivate let heartColor = Color.pink
fileprivate let darkHeartColor = Color(red: 0.369, green: 0.090, blue: 0.145) // dark pink

struct HeartChartDataPoint: Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let min: Double
    let max: Double
    let average: Double
    let median: Double
    let values: [Double]
}

struct HeartChartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    @AppStorage("minHeartRange") private var minHeartRange = 40
    @AppStorage("maxHeartRange") private var maxHeartRange = 200
    @AppStorage("heartPointMarkMode") private var heartPointMarkMode = "average"
    
    @State private var points = [HeartChartDataPoint]()
    @State private var loadedRange: DateInterval?
    @State private var scrollPositionDate: Date = Date()
    @State private var rawSelectedHour: Date? = nil
    @State private var displayedMin: Int = 40
    @State private var displayedMax: Int = 220
    
    private let cal = Calendar.current
    private let visibleDomain: TimeInterval = 86400
    
    var visiblePoints: [HeartChartDataPoint] {
        let visibleEnd = Date(timeInterval: 86400, since: scrollPositionDate)
        return points.filter { $0.date >= scrollPositionDate && $0.date <= visibleEnd }
    }
    var earliestDate: Date {
        points.map({ $0.date }).min() ?? Date()
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
    func pointMarkValue(for point: HeartChartDataPoint) -> Double {
        heartPointMarkMode == "average" ? point.average : point.median
    }
    
    func updateYScale() {
        displayedMin = Int(visiblePoints.map({ $0.min }).min() ?? 40)
        displayedMax = Int(visiblePoints.map({ $0.max }).max() ?? 220)
    }
    
    func fetchPoints(around date: Date) {
        let start = cal.date(byAdding: .day, value: -1, to: date)!
        let end = cal.date(byAdding: .day, value: 1, to: date)!
        let predicate = NSPredicate(
            format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@",
            bleManager.pairedDeviceID!,
            start as NSDate,
            end as NSDate
        )

        let raw = ChartManager.shared.heartPoints(predicate: predicate)
        if raw.isEmpty { return }
        
        points = process(raw)
        loadedRange = DateInterval(start: start, end: end)
    }
    
    func process(_ raw: [HeartDataPoint]) -> [HeartChartDataPoint] {
        let grouped = Dictionary(grouping: raw) { sample -> Date in
            let comps = cal.dateComponents([.year, .month, .day, .hour], from: sample.timestamp ?? Date())
            return cal.date(from: comps) ?? Date()
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
    
    func chart() -> some View {
        let xMin = cal.startOfDay(for: earliestDate)
        let xMax = cal.startOfDay(for: latestDate) + 86400 + 3600
        let yMin = displayedMin - 20
        let yMax = displayedMax + 20
        
        var chart: some View {
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
            .chartYScale(domain: yMin...yMax)
            .chartXScale(domain: xMin...xMax)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
        
        return Group {
            if #available(iOS 17, *) {
                chart
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
                chart
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let adjustedWidth = geo.size.width - 48
                                        let normalizedXPosition = min(max(value.location.x - 8, 0), adjustedWidth) / adjustedWidth
                                        rawSelectedHour = xMin.addingTimeInterval(normalizedXPosition * 86400)
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
    
    var body: some View {
        Group {
            if points.flatMap({ $0.values }).count <= 1 {
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
                            if let selectedViewHour {
                                let rangeFirstHour = cal.dateInterval(of: .hour, for: selectedViewHour.date)?.start ?? selectedViewHour.date
                                let rangeLastHour = cal.date(byAdding: .hour, value: 1, to: rangeFirstHour) ?? rangeFirstHour
                                
                                Text(isSingleReading(selectedViewHour) ? "\(Int(selectedViewHour.min)) " : "\(Int(selectedViewHour.min))–\(Int(selectedViewHour.max)) ")
                                    .font(.system(.title, design: .rounded))
                                    .foregroundColor(.primary)
                                + Text("BPM")
                                
                                let style = Date.FormatStyle().hour(.defaultDigits(amPM: .abbreviated))
                                Text("\(rangeFirstHour.formatted(.dateTime.month(.abbreviated).day())), \(rangeFirstHour.formatted(style))–\(rangeLastHour.formatted(style)) · \(selectedViewHour.values.count) \(selectedViewHour.values.count == 1 ? "reading" : "readings")\(selectedViewHour.values.count > 1 ? " · \(Int(pointMarkValue(for: selectedViewHour))) BPM \(pointMarkLabel)" : "")")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            } else {
                                Text(displayedMax == 0 || displayedMin == 0 ? "0 " : "\(displayedMin)–\(displayedMax) ")
                                    .font(.system(.title, design: .rounded))
                                    .foregroundColor(.primary)
                                + Text("BPM")
                                let rounded = Date(timeIntervalSinceReferenceDate: (scrollPositionDate.timeIntervalSinceReferenceDate / 3600).rounded() * 3600)
                                let end = Date(timeInterval: 86400, since: rounded)
                                let isFullDay = cal.component(.hour, from: rounded) == 0
                                Text(isFullDay
                                     ? rounded.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                                     : "\(rounded.formatted(.dateTime.month(.abbreviated).day())), \(rounded.formatted(.dateTime.hour().minute())) – \(end.formatted(.dateTime.month(.abbreviated).day())), \(end.formatted(.dateTime.hour().minute()))")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            }
                        }
                        .fontWeight(.semibold)
                        if #unavailable(iOS 17), selectedViewHour == nil {
                            Spacer()
                            scrollButton(-1, disabled: cal.startOfDay(for: scrollPositionDate) <= cal.startOfDay(for: earliestDate))
                            scrollButton(1, disabled: cal.startOfDay(for: scrollPositionDate) >= cal.startOfDay(for: latestDate))
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listRowBackground(Color.clear)
        .onAppear {
            fetchPoints(around: Date())
            scrollPositionDate = cal.startOfDay(for: latestDate)
            updateYScale()
        }
        .onChange(of: scrollPositionDate) { newValue in
            guard let loadedRange else { return }

            let threshold = visibleDomain / 2

            if newValue.timeIntervalSince(loadedRange.start) <= threshold ||
                newValue.timeIntervalSince(loadedRange.end) >= threshold {
                fetchPoints(around: newValue)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if scrollPositionDate == newValue {
                    updateYScale()
                }
            }
        }
        .onChange(of: bleManager.heartRate) { _ in
            let previousLatest = latestDate
            fetchPoints(around: Date())
            if !cal.isDate(latestDate, inSameDayAs: previousLatest) {
                scrollPositionDate = cal.startOfDay(for: latestDate)
            }
        }
        .onChange(of: selectedViewHour?.date) { newValue in
            guard newValue != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
