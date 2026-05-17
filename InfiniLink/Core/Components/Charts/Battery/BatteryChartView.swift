//
//  BatteryChartView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on May 17th 2026.
//

import SwiftUI
import Charts

struct BatteryChartDataPoint: Identifiable {
    var id = UUID()
    let date: Date
    let value: Double
}

struct BatteryChartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("batteryChartDataSelection") private var dataSelection = 0
    
    @State private var points = [BatteryChartDataPoint]()
    
    func batteryPoints() -> [BatteryChartDataPoint] {
        let raw = ChartManager.shared.batteryPoints().map {
            BatteryChartDataPoint(date: $0.timestamp ?? Date(), value: $0.value)
        }
        // Keep one point per hour (the last one in each bucket)
        let grouped = Dictionary(grouping: raw) { point -> Date in
            Calendar.current.dateInterval(of: .hour, for: point.date)!.start
        }
        return grouped.values.map { $0.last! }.sorted { $0.date < $1.date }
    }
    
    func startOfDay(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: Date()))!
    }

    
    var body: some View {
        Group {
            Group {
                if points.count <= 1 {
                    EmptyChartView(.battery)
                } else {
                    Section {
                        Chart(points) { point in
                            BarMark(
                                x: .value("Time", point.date),
                                y: .value("Percent", point.value)
                            )
                            .foregroundStyle(Color.green)
                        }
                        .frame(height: 280)
                        .chartYScale(domain: 0...100)
                        .chartXAxis {
                            AxisMarks(preset: .extended, values: .stride (by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartXScale(domain: startOfDay(daysAgo: 7)...Date())
                        .chartScrollableAxes(.horizontal)
                        .chartXVisibleDomain(length: 86400.0)
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
        .onAppear {
            points = batteryPoints()
        }
        .onChange(of: bleManager.batteryLevel) { _ in
            points = batteryPoints()
        }
    }
}
