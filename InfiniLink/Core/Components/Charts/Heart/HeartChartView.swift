//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import Charts

struct HeartChartDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let value: Double
}

struct HeartChartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject private var notificationSettings = NotificationSettingsManager.shared

    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0

    @State private var points = [HeartChartDataPoint]()

    private var heartRange: ClosedRange<Int> {
        let heart = notificationSettings.settings.heartSettings
        return heart.minRange...Swift.max(heart.minRange + 1, heart.maxRange)
    }

    func load() async {
        points = await ChartManager.shared.heartRateSamples().map { HeartChartDataPoint(date: $0.date, value: $0.value) }
    }
    var earliestDate: Date {
        return points.compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        return points.compactMap({ $0.date }).max() ?? Date()
    }
    var max: Int {
        return Int(points.compactMap({ $0.value }).max() ?? 0)
    }
    var min: Int {
        return Int(points.compactMap({ $0.value }).min() ?? 0)
    }
    
    var body: some View {
        Group {
            Group {
                if points.count <= 1 {
                    EmptyChartView(.heart)
                } else {
                    Section {
                        Chart(points) { point in
                            PointMark(
                                x: .value("Time", point.date),
                                y: .value("BPM", point.value)
                            )
                            .clipShape(Capsule())
                            .foregroundStyle(Color.red)
                        }
                        .frame(height: 280)
                        .chartYScale(domain: heartRange)
                    } header: {
                        VStack(alignment: .leading) {
                            Text(points.count > 1 ? "Range" : "No Data")
                            if max == 0 || min == 0 {
                                Text(0, format: .number)
                                    .font(.system(.title, design: .rounded))
                                    .foregroundColor(.primary)
                                + Text(" BPM")
                            } else {
                                (Text(min, format: .number) + Text("-") + Text(max, format: .number))
                                    .font(.system(.title, design: .rounded))
                                    .foregroundColor(.primary)
                                + Text(" BPM")
                            }
                            Text("\(earliestDate.formatted(.dateTime.month(.abbreviated).day()))-\(latestDate.formatted(.dateTime.day()))")
                        }
                        .fontWeight(.semibold)
                    }
                    .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .listRowBackground(Color.clear)
            if points.count >= 3 {
                Section {
                    Text("Today your heart rate reached a high of \(max), and dropped to a low of \(min) BPM.")
                    // Text("Is a heart point in an exercise in the last day: \(ExerciseViewModel.shared.isDateDuringExercise(Date()))")
                }
            }
        }
        .task {
            await load()
        }
        .onChange(of: bleManager.heartRate) { _ in
            Task { await load() }
        }
    }
}
