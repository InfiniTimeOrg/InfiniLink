//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import Charts

struct HeartChartDataPoint {
    var id = UUID()
    let date: Date
    let min: Double
    let max: Double
}

struct HeartChartView: View {
    @ObservedObject var chartManager = ChartManager.shared
    
    let showHeader: Bool
    
    func data() -> [HeartChartDataPoint] {
        let points = [
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 1), min: 200, max: 239),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 2), min: 101, max: 184),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 3), min: 96, max: 193),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 4), min: 104, max: 202),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 5), min: 90, max: 95),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 6), min: 96, max: 203),
            HeartChartDataPoint(date: date(year: 2025, month: 7, day: 7), min: 98, max: 200)
        ]
        
        // TODO: return data in proper format
        
        return points
    }
    var earliestDate: Date {
        data().compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        data().compactMap({ $0.date }).max() ?? Date()
    }
    
    var header: some View {
        VStack(alignment: .leading) {
            Text(data().count > 1 ? "Range" : " ")
            Text({
                let max = Int(data().compactMap({ $0.max }).max() ?? 0)
                let min = Int(data().compactMap({ $0.min }).min() ?? 0)
                
                if max == 0 || min == 0 {
                    return "0 "
                } else {
                    return "\(min)-\(max) "
                }
            }())
            .font(.system(.title, design: .rounded))
            .foregroundColor(.primary)
            + Text("BPM")
            Text("\(earliestDate.formatted())-\(latestDate.formatted())")
        }
        .fontWeight(.semibold)
    }
    
    init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    var body: some View {
        Section(header: showHeader ? AnyView(header) : AnyView(Text("Heart Rate"))) {
            Chart(data(), id: \.id) { point in
                Plot {
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        yStart: .value("BPM Min", point.min),
                        yEnd: .value("BPM Max", point.max),
                        width: .fixed(8)
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(Color.red)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 300)
        }
    }
}
