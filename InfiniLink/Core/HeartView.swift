//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import CoreData
import Charts

struct HeartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared

    @State private var samples: [HeartRateSample] = []
    @State private var hasLoaded = false

    var values: [Double] {
        return samples.map { $0.value }
    }

    func load() async {
        samples = await chartManager.heartRateSamples()
        // Wait until the first value shows so it doesn't animate on appear
        if !hasLoaded {
            DispatchQueue.main.async {
                hasLoaded = true
            }
        }
    }

    func heartRate(for val: Double) -> String {
        return String(format: "%.0f", max(val, 0))
    }
    func units(for seconds: Int) -> String {
        if seconds >= 172800 {
            return NSLocalizedString("Several days ago", comment: "")
        } else if seconds >= 86400 {
            let days = seconds / 86400
            return NSLocalizedString("\(days) day\(days == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 3600 {
            let hours = seconds / 3600
            return NSLocalizedString("\(hours) hour\(hours == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 60 {
            let minutes = seconds / 60
            return NSLocalizedString("\(minutes) minute\(minutes == 1 ? "" : "s") ago", comment: "")
        }
        return NSLocalizedString("Now", comment: "")
    }
    func timestamp(for date: Date?) -> String? {
        guard let timeInterval = date?.timeIntervalSinceNow else { return nil }

        return units(for: Int(abs(timeInterval)))
    }

    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(format: "%.0f", values.last ?? 0), subtitle: timestamp(for: samples.last?.date), units: "BPM", icon: "heart.fill", accent: .red), width: geo.size.width, animate: (samples.last?.date.timeIntervalSinceNow ?? 60) < 60, animateTitle: hasLoaded) {
                        if !values.isEmpty {
                            HStack {
                                DetailHeaderSubItemView(
                                    title: "Min",
                                    value: heartRate(for: values.min() ?? 0),
                                    icon: ("arrow.down.heart", .red.opacity(0.7))
                                )
                                DetailHeaderSubItemView(
                                    title: "Avg",
                                    value: heartRate(for: {
                                        let ints = values.compactMap { Int($0) }
                                        guard ints.count > 0 else { return 0.0 }
                                        return Double(ints.reduce(0, +)) / Double(ints.count)
                                    }()),
                                    icon: ("heart", .red.opacity(0.7))
                                )
                                DetailHeaderSubItemView(
                                    title: "Max",
                                    value: heartRate(for: values.max() ?? 0),
                                    icon: ("bolt.heart", .red.opacity(0.7))
                                )
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                HeartChartView()
                RestingHeartRateView()
            }
        }
        .navigationTitle("Heart Rate")
        .task {
            await load()
        }
        .onChange(of: bleManager.heartRate) { _ in
            Task { await load() }
        }
        .toolbar {
            NavigationLink {
                HeartSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct RestingHeartRateView: View {
    @State private var days = [RestingHeartRateDay]()
    
    var body: some View {
        Section("Resting Heart Rate") {
            if days.count > 1 {
                Chart(days) { day in
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("BPM", day.bpm)
                    )
                    .foregroundStyle(.red)
                    PointMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("BPM", day.bpm)
                    )
                    .foregroundStyle(.red)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 8)
                Text("Your resting heart rate has averaged \(Int((days.reduce(0) { $0 + $1.bpm } / Double(days.count)).rounded())) BPM this past week.")
            } else {
                Text("Not enough heart rate data yet. Resting heart rate is estimated from readings taken while you're still during the day.")
                    .foregroundStyle(.gray)
            }
        }
        .onAppear {
            guard let deviceId = DeviceManager.shared.pairedDeviceID else { return }
            
            HealthTrends().restingHeartRates(days: 7, deviceId: deviceId) { days in
                self.days = days
            }
        }
    }
}

#Preview {
    NavigationView {
        HeartView()
            .onAppear {
                BLEManager.shared.heartRate = 76
            }
            .navigationBarTitleDisplayMode(.inline)
    }
}
