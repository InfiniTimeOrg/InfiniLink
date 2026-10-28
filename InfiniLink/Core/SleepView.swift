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
    var level: Double {
        switch self {
        case .awake:
            return 2
        case .asleep:
            return 1
        case .noData:
            return 0
        }
    }
}

struct SleepNight: Identifiable {
    let id = UUID()
    let date: Date
    let asleepMinutes: Int
}

struct SleepView: View {
    @ObservedObject var sleepManager = SleepManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared

    @StateObject private var editor = WatchSettingsEditor()

    @State private var sessions = [SleepSession]()

    private var lastNight: [SleepSession] {
        guard let latest = sessions.last?.start, let window = SleepAnalyzer.window(containing: latest) else { return [] }
        return sessions.filter { window.contains($0.start ?? .distantPast) }
    }

    private var lastNightAsleep: Int {
        lastNight.reduce(0) { $0 + Int($1.asleepMinutes) }
    }
    private var lastNightAwake: Int {
        lastNight.reduce(0) { $0 + Int($1.awakeMinutes) }
    }

    private var runs: [SleepRun] {
        lastNight.flatMap { session -> [SleepRun] in
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
    }

    private var hourMarks: [Date] { // About four whole hours across the night, like Health
        guard let start = runs.first?.start, let end = runs.last?.end,
              let first = Calendar.current.nextDate(after: start.addingTimeInterval(-1), matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime) else { return [] }
        let step = max(1, Int(ceil(end.timeIntervalSince(first) / 3600 / 4)))

        return stride(from: first, through: end, by: Double(step) * 3600).map { $0 }
    }

    private var transitions: [(date: Date, from: SleepState, to: SleepState)] {
        zip(runs, runs.dropFirst()).compactMap { $0.end == $1.start ? ($0.end, $0.state, $1.state) : nil }
    }

    private var nights: [SleepNight] { // Group by the morning that nights ended
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.end ?? Date()) }

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: Date())) else { return nil }
            let minutes = grouped[day]?.reduce(0) { $0 + Int($1.asleepMinutes) } ?? 0

            return SleepNight(date: day, asleepMinutes: minutes)
        }
        .reversed()
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
                Section {
                    DetailHeaderView(Header(title: duration(lastNightAsleep), subtitle: lastNightAsleep == 0 ? NSLocalizedString("No sleep recorded last night", comment: "") : NSLocalizedString("Last night", comment: ""), icon: "bed.double.fill", accent: .indigo), width: geo.size.width) {
                        let recorded = nights.filter { $0.asleepMinutes > 0 }
                        let slept = lastNightAsleep > 0
                        if slept || !recorded.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                                DetailHeaderSubItemView(title: "Fell Asleep", value: slept ? lastNight.first?.start?.formatted(.dateTime.hour().minute()) ?? "--" : "--", icon: ("moon.fill", .indigo))
                                DetailHeaderSubItemView(title: "Woke Up", value: slept ? lastNight.last?.end?.formatted(.dateTime.hour().minute()) ?? "--" : "--", icon: ("sun.max.fill", .orange))
                                DetailHeaderSubItemView(title: "Awake", value: slept ? duration(lastNightAwake) : "--", icon: ("eye.fill", .orange))
                                DetailHeaderSubItemView(title: "Daily Avg", value: recorded.isEmpty ? "--" : duration(recorded.reduce(0) { $0 + $1.asleepMinutes } / recorded.count), icon: ("chart.bar.fill", .indigo))
                            }
                        }
                    }
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
                                let upper = transition.from.level > transition.to.level ? transition.from : transition.to
                                let lower = upper == transition.from ? transition.to : transition.from
                                RuleMark(
                                    x: .value("Time", transition.date),
                                    yStart: .value("State", lower.level),
                                    yEnd: .value("State", upper.level)
                                )
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                .foregroundStyle(LinearGradient(colors: [upper.color, lower.color], startPoint: .top, endPoint: .bottom).opacity(0.4))
                            }
                            ForEach(runs) { run in
                                RectangleMark(
                                    xStart: .value("Start", run.start),
                                    xEnd: .value("End", run.end),
                                    yStart: .value("State", run.state.level - 0.3),
                                    yEnd: .value("State", run.state.level + 0.3)
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("State", run.state.name))
                            }
                        }
                        .chartForegroundStyleScale(domain: SleepState.allCases.map(\.name), range: SleepState.allCases.map(\.color))
                        .chartYScale(domain: -0.5...2.5)
                        .chartYAxis {
                            AxisMarks(values: [0.5, 1.5]) {
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
                        .frame(height: 200)
                        .padding(.vertical, 8)
                        .accessibilityLabel(Text("Sleep timeline for last night"))
                    }
                }
                if nights.allSatisfy({ $0.asleepMinutes == 0 }) {
                    Section {
                        EmptyChartView(.sleep)
                    }
                } else {
                    Section("Past Week") {
                        Chart(nights) { night in
                            BarMark(
                                x: .value("Night", night.date, unit: .day),
                                y: .value("Hours Asleep", Double(night.asleepMinutes) / 60)
                            )
                            .foregroundStyle(.indigo)
                            .accessibilityValue(Text(duration(night.asleepMinutes)))
                        }
                        .chartXAxis {
                            AxisMarks(values: nights.map { $0.date }) {
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartYAxisLabel("Hours")
                        .frame(height: 220)
                        .padding(.vertical, 8)
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
    }
}

#Preview {
    NavigationStack {
        SleepView()
    }
}
