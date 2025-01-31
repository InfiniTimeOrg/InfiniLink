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
    @ObservedObject var chartManager = ChartManager.shared
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    
    let showHeader: Bool
    
    func data() -> [HeartChartDataPoint] {
        return chartManager.heartPoints().compactMap { point in
            return HeartChartDataPoint(date: point.timestamp!, value: point.value)
        }
    }
    var earliestDate: Date {
        data().compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        data().compactMap({ $0.date }).max() ?? Date()
    }
    var header: some View {
        VStack(alignment: .leading) {
            Text(data().count > 1 ? "Range" : "No Data")
            Text({
                let max = Int(data().compactMap({ $0.value }).max() ?? 0)
                let min = Int(data().compactMap({ $0.value }).min() ?? 0)
                
                if max == 0 || min == 0 {
                    return "0 "
                } else {
                    return "\(min)-\(max) "
                }
            }())
            .font(.system(.title, design: .rounded))
            .foregroundColor(.primary)
            + Text("BPM")
            Text("\(earliestDate.formatted(.dateTime.month(.abbreviated).day()))-\(latestDate.formatted(.dateTime.day()))")
        }
        .fontWeight(.semibold)
    }
    
    init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    var body: some View {
        Group {
            Section {
                Picker("Range", selection: $dataSelection) {
                    ForEach(0...3, id: \.self) { index in
                        Text({
                            switch index {
                            case 0: return "H"
                            case 1: return "D"
                            case 2: return "W"
                            case 3: return "M"
                            default: return "-"
                            }
                        }())
                        .tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
            Section(header: showHeader ? AnyView(header) : AnyView(Text("Heart Rate"))) {
                Chart(data()) { point in
                    Plot {
                        BarMark(
                            x: .value("Day", point.date),
                            y: .value("BPM Min", point.value)
                        )
                        .clipShape(Capsule())
                        .foregroundStyle(Color.red)
                    }
                }
//                .chartXAxis {
//                    AxisMarks(values: .stride(by: .day)) { _ in
//                        AxisTick()
//                        AxisGridLine()
//                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
//                    }
//                }
                .frame(height: 250)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
