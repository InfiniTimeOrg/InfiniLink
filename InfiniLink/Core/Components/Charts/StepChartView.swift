//
//  StepChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/11/25.
//

import SwiftUI
import Charts

struct StepChartDataPoint {
    var id = UUID()
    let date: Date
    let steps: Int
}

struct StepChartView: View {
    func data() -> [StepChartDataPoint] {
        let points = [
            StepChartDataPoint(date: date(year: 2025, month: 7, day: 1), steps: 239),
            StepChartDataPoint(date: date(year: 2025, month: 6, day: 2), steps: 184),
            StepChartDataPoint(date: date(year: 2025, month: 5, day: 3), steps: 7655),
            StepChartDataPoint(date: date(year: 2025, month: 4, day: 4), steps: 202),
            StepChartDataPoint(date: date(year: 2025, month: 3, day: 5), steps: 3402),
            StepChartDataPoint(date: date(year: 2025, month: 2, day: 6), steps: 1890),
            StepChartDataPoint(date: date(year: 2025, month: 1, day: 3), steps: 9002),
            StepChartDataPoint(date: date(year: 2025, month: 1, day: 7), steps: 788)
        ]
        
        // TODO: return data in proper format
        
        return points
    }
    
    var header: some View {
        VStack(alignment: .leading) {
            Text(data().count > 1 ? "Range" : " ")
            Text({
                let max = Int(data().compactMap({ $0.steps }).max() ?? 0)
                let min = Int(data().compactMap({ $0.steps }).min() ?? 0)
                
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
    var earliestDate: Date {
        data().compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        data().compactMap({ $0.date }).max() ?? Date()
    }
    
    var body: some View {
        Chart(data(), id: \.date) {
            BarMark(
                x: .value("Date", $0.date),
                y: .value("Steps", $0.steps),
                width: .automatic
            )
            .accessibilityLabel($0.date.formatted(date: .complete, time: .omitted))
            .accessibilityValue("\($0.steps) steps")
            .foregroundStyle(.blue)
        }
        .frame(height: 300)
    }
}
