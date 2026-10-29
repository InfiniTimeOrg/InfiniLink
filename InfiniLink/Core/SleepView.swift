//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI
import Charts

struct SleepRun: Identifiable {
    let id = UUID()
    let state: SleepState
    let start: Date
    let end: Date

    var minutes: Int {
        Int(end.timeIntervalSince(start) / 60)
    }
}

extension SleepState {
    var name: String {
        switch self {
        case .asleep:
            return NSLocalizedString("Asleep", comment: "")
        case .awake:
            return NSLocalizedString("Awake", comment: "")
        case .noData:
            return NSLocalizedString("Unmeasurable", comment: "")
        }
    }
    var color: Color {
        switch self {
        case .asleep:
            return .indigo
        case .awake:
            return .orange
        case .noData:
            return .gray
        }
    }
}

struct SleepStripView: View {
    let runs: [SleepRun]

    var body: some View {
        GeometryReader { geo in
            let total = max(1, runs.reduce(0) { $0 + $1.minutes })
            HStack(spacing: 0) {
                ForEach(runs) { run in
                    Rectangle()
                        .fill(run.state.color)
                        .frame(width: geo.size.width * CGFloat(run.minutes) / CGFloat(total))
                }
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

struct SleepNight: Identifiable {
    let id = UUID()
    let date: Date
    let asleepMinutes: Int
    let napMinutes: Int
    let start: Date?
    let end: Date?
}

struct SleepView: View {
    @ObservedObject var sleepManager = SleepManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared

    @StateObject private var editor = WatchSettingsEditor()

    @State private var sessions = [SleepSession]()

    private var nightSessions: [SleepSession] {
        sessions.filter { !$0.isNap }
    }
    private var naps: [SleepSession] {
        sessions.filter { $0.isNap }
    }
    private var napsToday: [SleepSession] {
        naps.filter { Calendar.current.isDateInToday($0.start ?? .distantPast) }
    }

    private var lastNight: [SleepSession] {
        guard let latest = nightSessions.last?.start, let window = SleepAnalyzer.window(containing: latest) else { return [] }
        return nightSessions.filter { window.contains($0.start ?? .distantPast) }
    }

    private var lastNightAsleep: Int {
        lastNight.reduce(0) { $0 + Int($1.asleepMinutes) }
    }
    private var lastNightAwake: Int {
        lastNight.reduce(0) { $0 + Int($1.awakeMinutes) }
    }

    private var runs: [SleepRun] {
        lastNight.flatMap(runs(for:))
    }

    private func runs(for session: SleepSession) -> [SleepRun] {
        let states = sleepManager.states(for: session)
        guard let start = session.start, !states.isEmpty else { return [] }

        var runs = [SleepRun]()
        var runStart = 0
        for index in 1...states.count where index == states.count || states[index] != states[runStart] {
            runs.append(SleepRun(state: states[runStart], start: start.addingTimeInterval(Double(runStart) * 60), end: start.addingTimeInterval(Double(index) * 60)))
            runStart = index
        }
        return runs
    }

    private var hourMarks: [Date] { // About four whole hours across the night, like Health
        guard let start = runs.first?.start, let end = runs.last?.end,
              let first = Calendar.current.nextDate(after: start.addingTimeInterval(-1), matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime) else { return [] }
        let step = max(1, Int(ceil(end.timeIntervalSince(first) / 3600 / 4)))

        return stride(from: first, through: end, by: Double(step) * 3600).map { $0 }
    }

    // Only rows with time in them, awake on top
    private var visibleStates: [SleepState] {
        SleepState.allCases.filter { minutes(in: $0) > 0 }
    }
    private func row(for state: SleepState) -> Double {
        Double(visibleStates.count - 1 - (visibleStates.firstIndex(of: state) ?? 0))
    }

    private func minutes(in state: SleepState) -> Int {
        runs.filter { $0.state == state }.reduce(0) { $0 + $1.minutes }
    }

    private var transitions: [(date: Date, from: SleepState, to: SleepState)] {
        zip(runs, runs.dropFirst()).compactMap { $0.end == $1.start ? ($0.end, $0.state, $1.state) : nil }
    }

    private var nights: [SleepNight] { // Nights go on the morning they ended, naps on the day they happened
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: nightSessions) { calendar.startOfDay(for: $0.end ?? Date()) }
        let groupedNaps = Dictionary(grouping: naps) { calendar.startOfDay(for: $0.start ?? Date()) }

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())) else { return nil }
            let minutes = grouped[day]?.reduce(0) { $0 + Int($1.asleepMinutes) } ?? 0
            let napMinutes = groupedNaps[day]?.reduce(0) { $0 + Int($1.asleepMinutes) } ?? 0

            return SleepNight(date: day, asleepMinutes: minutes, napMinutes: napMinutes, start: grouped[day]?.first?.start, end: grouped[day]?.last?.end)
        }
        .reversed()
    }

    private var scheduledNights: [SleepNight] {
        nights.filter { $0.start != nil && $0.end != nil }
    }

    private func minuteOfDay(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    // Minutes into the night, with the end always after the start
    private func nightSpan(from start: Int, to end: Int) -> (start: Int, end: Int) {
        let startMinute = (start - SleepAnalyzer.windowMinutes.start + 1440 + 360) % 1440 - 360
        return (startMinute, startMinute + (end - start + 1440) % 1440)
    }

    // Big enough for the schedule and every night, on whole hours
    private var nightRange: ClosedRange<Int> {
        let schedule = sleepManager.schedule
        let spans = [nightSpan(from: schedule.bedtime, to: schedule.wake)] + scheduledNights.compactMap { night -> (start: Int, end: Int)? in
            guard let start = night.start, let end = night.end else { return nil }
            return nightSpan(from: minuteOfDay(start), to: minuteOfDay(end))
        }
        let origin = SleepAnalyzer.windowMinutes.start
        let low = spans.map(\.start).min() ?? 0
        let high = spans.map(\.end).max() ?? 0

        return (low - ((origin + low) % 60 + 60) % 60)...(high + (60 - ((origin + high) % 60 + 60) % 60) % 60)
    }

    // Negative so the night reads top to bottom
    private var nightDomain: ClosedRange<Double> {
        -Double(nightRange.upperBound) / 60...(-Double(nightRange.lowerBound) / 60)
    }
    private var nightHourMarks: [Double] {
        stride(from: nightRange.lowerBound, through: nightRange.upperBound, by: 180).map { -Double($0) / 60 }
    }
    private var scheduledHours: (start: Double, end: Double) {
        let span = nightSpan(from: sleepManager.schedule.bedtime, to: sleepManager.schedule.wake)
        return (-Double(span.start) / 60, -Double(span.end) / 60)
    }
    private func sleptHours(_ night: SleepNight) -> (start: Double, end: Double)? {
        guard let start = night.start, let end = night.end else { return nil }
        let span = nightSpan(from: minuteOfDay(start), to: minuteOfDay(end))
        return (-Double(span.start) / 60, -Double(span.end) / 60)
    }
    private func nightTime(_ hours: Double) -> String {
        SleepSchedule.time(((SleepAnalyzer.windowMinutes.start + Int((-hours * 60).rounded())) % 1440 + 1440) % 1440)
    }

    private var onTimeNights: Int {
        scheduledNights.filter { night in
            guard let start = night.start else { return false }
            let difference = abs(minuteOfDay(start) - sleepManager.schedule.bedtime)
            return min(difference, 1440 - difference) <= 30
        }.count
    }

    private var recordedNights: [SleepNight] {
        nights.filter { $0.asleepMinutes > 0 }
    }

    private var lastNightGapMinutes: Int { // Gaps between sessions count as being awake
        zip(lastNight, lastNight.dropFirst()).reduce(0) { total, pair in
            guard let end = pair.0.end, let start = pair.1.start else { return total }
            return total + Int(start.timeIntervalSince(end) / 60)
        }
    }
    private var lastNightWakeUps: Int {
        runs.filter { $0.state == .awake }.count + max(0, lastNight.count - 1)
    }

    private var headerSubtitle: String? {
        if !napsToday.isEmpty {
            let napTime = duration(napsToday.reduce(0) { $0 + Int($1.asleepMinutes) })
            return napsToday.count == 1 ? String(localized: "1 nap today • \(napTime)") : String(localized: "\(napsToday.count) naps today • \(napTime)")
        }
        return lastNightAsleep == 0 ? NSLocalizedString("No sleep recorded last night", comment: "") : nil
    }

    private var lastNightSummary: String? {
        guard let start = lastNight.first?.start, let end = lastNight.last?.end else { return nil }

        let times = String(localized: "You fell asleep at \(start.formatted(.dateTime.hour().minute())) and woke up at \(end.formatted(.dateTime.hour().minute())).")
        let awake = duration(lastNightAwake + lastNightGapMinutes)
        switch lastNightWakeUps {
        case 0:
            return times + " " + String(localized: "You slept \(duration(lastNightAsleep)) without waking up.") + goalSummary
        case 1:
            return times + " " + String(localized: "You woke up once for \(awake), but still slept \(duration(lastNightAsleep)).") + goalSummary
        default:
            return times + " " + String(localized: "You woke up \(lastNightWakeUps) times for a total of \(awake), but still slept \(duration(lastNightAsleep)).") + goalSummary
        }
    }

    private var goalSummary: String {
        let schedule = sleepManager.schedule
        guard schedule.enabled else { return "" }

        if schedule.meetsGoal(asleepMinutes: lastNightAsleep) {
            return " " + NSLocalizedString("You met your sleep goal.", comment: "")
        }
        return " " + String(localized: "That's \(duration(schedule.goalMinutes - lastNightAsleep)) short of your goal.")
    }

    private func duration(_ minutes: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated

        return formatter.string(from: TimeInterval(minutes * 60)) ?? "\(minutes)m"
    }

    private func load() {
        sessions = sleepManager.recentSessions()
    }

    var body: some View {
        GeometryReader { geo in
            List {
                if !sleepManager.schedule.enabled {
                    Section {
                        NavigationLink {
                            SleepSettingsView()
                        } label: {
                            BannerView("Set a Sleep Schedule", "Track naps and get a reminder when it's time for bed.") {
                                Image(systemName: "alarm.fill")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(.indigo)
                            }
                        }
                    }
                }
                Section {
                    DetailHeaderView(Header(title: duration(lastNightAsleep), subtitle: headerSubtitle, icon: "bed.double.fill", accent: .indigo), width: geo.size.width) {}
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                if !sleepManager.hasRequiredMeasurements {
                    Section {
                        Label("Sleep tracking needs \(deviceManager.name) to measure your heart rate in the background at least every 10 minutes.", systemImage: "heart.text.square.fill")
                        if let file = editor.file, !editor.usingDefaults {
                            Picker("Background Measurements", selection: Binding(
                                get: { file.heartRateBackgroundPeriod.flatMap { SleepManager.backgroundPeriods.contains($0) ? $0 : nil } ?? 300 },
                                set: { editor.file?.heartRateBackgroundPeriod = $0 }
                            )) {
                                Text("Continuous").tag(UInt16(0))
                                Text("30 seconds").tag(UInt16(30))
                                Text("1 minute").tag(UInt16(60))
                                Text("5 minutes").tag(UInt16(300))
                                Text("10 minutes").tag(UInt16(600))
                            }
                            Button {
                                // The picker shows 5 min by default, so make sure that's actually what gets saved
                                if !SleepManager.backgroundPeriods.contains(editor.file?.heartRateBackgroundPeriod ?? UInt16.max) {
                                    editor.file?.heartRateBackgroundPeriod = 300
                                }
                                editor.requestSave()
                            } label: {
                                HStack {
                                    Text("Save to Watch")
                                    if editor.isSaving {
                                        Spacer()
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(editor.isSaving)
                        } else if editor.file != nil {
                            Text("\(deviceManager.name) is using its default settings. Save them in Customization first, then turn this on.")
                                .foregroundStyle(.gray)
                        } else if !editor.isLoading {
                            Text("Connect \(deviceManager.name) to turn on background measurements.")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                if !runs.isEmpty {
                    Section("Last Night") {
                        Chart {
                            ForEach(transitions, id: \.date) { transition in
                                let upper = row(for: transition.from) > row(for: transition.to) ? transition.from : transition.to
                                let lower = upper == transition.from ? transition.to : transition.from
                                RuleMark(
                                    x: .value("Time", transition.date),
                                    yStart: .value("State", row(for: lower)),
                                    yEnd: .value("State", row(for: upper))
                                )
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                .foregroundStyle(LinearGradient(colors: [upper.color, lower.color], startPoint: .top, endPoint: .bottom).opacity(0.4))
                            }
                            ForEach(runs) { run in
                                RectangleMark(
                                    xStart: .value("Start", run.start),
                                    xEnd: .value("End", run.end),
                                    yStart: .value("State", row(for: run.state) - 0.3),
                                    yEnd: .value("State", row(for: run.state) + 0.3)
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("State", run.state.name))
                            }
                        }
                        .chartForegroundStyleScale(domain: SleepState.allCases.map(\.name), range: SleepState.allCases.map(\.color))
                        .chartYScale(domain: -0.5...(Double(visibleStates.count) - 0.5))
                        .chartYAxis {
                            AxisMarks(position: .leading, values: visibleStates.map(row(for:))) { value in
                                AxisValueLabel {
                                    if let state = visibleStates.first(where: { row(for: $0) == value.as(Double.self) }) {
                                        Text(duration(minutes(in: state)))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            AxisMarks(values: Array(stride(from: 0.5, to: Double(visibleStates.count) - 1, by: 1))) {
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: hourMarks) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: CGFloat(visibleStates.count) * 60 + 20)
                        .padding(.vertical, 8)
                        .accessibilityLabel(Text("Sleep timeline for last night"))
                        if let lastNightSummary {
                            Text(lastNightSummary)
                        }
                    }
                }
                if sleepManager.schedule.enabled && !napsToday.isEmpty {
                    Section("Naps") {
                        ForEach(napsToday.reversed(), id: \.objectID) { nap in
                            if let start = nap.start, let end = nap.end {
                                VStack(spacing: 10) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text((start..<end).formatted(.interval.hour().minute()))
                                            Text(start, format: .dateTime.weekday(.wide).month().day())
                                                .font(.subheadline)
                                                .foregroundStyle(.gray)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(duration(Int(nap.asleepMinutes)))
                                                .fontWeight(.semibold)
                                            if nap.awakeMinutes > 0 {
                                                Text("\(duration(Int(nap.awakeMinutes))) awake")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    }
                                    let napRuns = runs(for: nap)
                                    if napRuns.contains(where: { $0.state != .asleep }) {
                                        SleepStripView(runs: napRuns)
                                    }
                                }
                                .padding(.vertical, 2)
                                .accessibilityElement(children: .combine)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        sleepManager.deleteNap(nap)
                                        load()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                if nights.allSatisfy({ $0.asleepMinutes == 0 && $0.napMinutes == 0 }) {
                    Section {
                        EmptyChartView(.sleep)
                    }
                } else {
                    Section("Past Week") {
                        Chart {
                            if sleepManager.schedule.enabled {
                                RuleMark(y: .value("Goal", Double(sleepManager.schedule.goalMinutes) / 60))
                                    .foregroundStyle(.gray)
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                                    .annotation(position: .top, alignment: .leading) {
                                        Text("Goal")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.gray)
                                    }
                            }
                            ForEach(nights) { night in
                                BarMark(
                                    x: .value("Night", night.date, unit: .day),
                                    y: .value("Hours Asleep", Double(night.asleepMinutes) / 60)
                                )
                                .foregroundStyle(by: .value("Type", NSLocalizedString("Sleep", comment: "")))
                                .accessibilityValue(Text(duration(night.asleepMinutes)))
                                BarMark(
                                    x: .value("Night", night.date, unit: .day),
                                    y: .value("Hours Asleep", Double(night.napMinutes) / 60)
                                )
                                .foregroundStyle(by: .value("Type", NSLocalizedString("Naps", comment: "")))
                                .accessibilityValue(Text(duration(night.napMinutes)))
                            }
                        }
                        .chartForegroundStyleScale(domain: [NSLocalizedString("Sleep", comment: ""), NSLocalizedString("Naps", comment: "")], range: [Color.indigo, Color.gray])
                        .chartLegend(naps.isEmpty ? .hidden : .automatic)
                        .chartXAxis {
                            AxisMarks(values: nights.map { $0.date }) {
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartYAxisLabel("Hours")
                        .frame(height: 220)
                        .padding(.vertical, 8)
                        if !recordedNights.isEmpty {
                            Text("You've averaged \(duration(recordedNights.reduce(0) { $0 + $1.asleepMinutes } / recordedNights.count)) of sleep this week.")
                        }
                    }
                }
                if sleepManager.schedule.enabled && !scheduledNights.isEmpty {
                    Section("Schedule") {
                        Chart {
                            RectangleMark(
                                yStart: .value("Bedtime", scheduledHours.start),
                                yEnd: .value("Wake Up", scheduledHours.end)
                            )
                            .foregroundStyle(.indigo.opacity(0.15))
                            ForEach(scheduledNights) { night in
                                if let start = night.start, let end = night.end, let hours = sleptHours(night) {
                                    BarMark(
                                        x: .value("Night", night.date, unit: .day),
                                        yStart: .value("Fell Asleep", hours.start),
                                        yEnd: .value("Woke Up", hours.end)
                                    )
                                    .cornerRadius(4)
                                    .foregroundStyle(.indigo)
                                    .accessibilityValue(Text("\(start.formatted(.dateTime.hour().minute())) to \(end.formatted(.dateTime.hour().minute()))"))
                                }
                            }
                        }
                        .chartYScale(domain: nightDomain)
                        .chartXScale(domain: (nights.first?.date ?? Date())...(Calendar.current.date(byAdding: .day, value: 1, to: nights.last?.date ?? Date()) ?? Date()))
                        .chartYAxis {
                            AxisMarks(values: nightHourMarks) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let hours = value.as(Double.self) {
                                        Text(nightTime(hours))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: nights.map { $0.date }) {
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .frame(height: 220)
                        .padding(.vertical, 8)
                        Text("You fell asleep within 30 minutes of your bedtime on \(onTimeNights) of \(scheduledNights.count) nights.")
                    }
                }
            }
        }
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            load()
            if sleepManager.hasRequiredMeasurements {
                sleepManager.process {
                    load()
                }
            } else if editor.file == nil {
                editor.load()
            }
        }
        .modifier(WatchSettingsAlerts(editor: editor, deviceName: deviceManager.name))
        .toolbar {
            NavigationLink {
                SleepSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SleepView()
    }
}
