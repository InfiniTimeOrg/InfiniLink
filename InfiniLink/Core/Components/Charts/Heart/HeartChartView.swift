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
            if points.count <= 1 {
                EmptyChartView(.heart)
                    .listRowBackground(Color.clear)
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
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 0))
                    if points.count >= 3 {
                        Text(([String(localized: "Today your heart rate reached a high of \(max), and dropped to a low of \(min) BPM.")] + [notificationSummary].compactMap { $0 }).joined(separator: "\n\n"))
                    }
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
