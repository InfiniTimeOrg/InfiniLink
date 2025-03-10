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
    
    func heartPoints() -> [HeartChartDataPoint] {
        let now = Date()
        let calendar = Calendar.current
        
        let points = chartManager.heartPoints().map { point in
            let timestamp = point.timestamp ?? Date() // Should we catch this date?
            let dataPoint = HeartChartDataPoint(date: timestamp, value: point.value)
            
            return dataPoint
        }
        return points.filter { point in
            switch dataSelection {
            case 1:
                if calendar.isDate(point.date, equalTo: now, toGranularity: .day) {
                    return true
                }
            case 2:
                if calendar.isDate(point.date, equalTo: now, toGranularity: .weekOfYear) {
                    return true
                }
            case 3:
                if calendar.isDate(point.date, equalTo: now, toGranularity: .month) {
                    return true
                }
            default:
                if calendar.isDate(point.date, equalTo: now, toGranularity: .hour) {
                    return true
                }
            }
            
            return false
        }
    }
    var earliestDate: Date {
        return heartPoints().compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        return heartPoints().compactMap({ $0.date }).max() ?? Date()
    }
    var max: Int {
        return Int(heartPoints().compactMap({ $0.value }).max() ?? 0)
    }
    var min: Int {
        return Int(heartPoints().compactMap({ $0.value }).min() ?? 0)
    }
    
    var body: some View {
        Group {
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
                if heartPoints().count <= 1 {
                    EmptyChartView(.heart)
                } else {
                    Section {
                        Chart(heartPoints()) { point in
                            BarMark(
                                x: .value("Day", point.date),
                                y: .value("BPM Min", point.value)
                            )
                            .clipShape(Capsule())
                            .foregroundStyle(Color.red)
                        }
                        .frame(height: 280)
                    } header: {
                        VStack(alignment: .leading) {
                            Text(heartPoints().count > 1 ? "Range" : "No Data")
                            Text({
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
                    .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
                }
            }
            .listRowBackground(Color.clear)
            Section {
                Text("Today your heart rate reached a high of \(max), and dropped to a low of \(min) BPM.")
//                Text("Is a heart point in an exercise in the last day: \(ExerciseViewModel.shared.isDateDuringExercise(Date()))")
            }
        }
    }
}
