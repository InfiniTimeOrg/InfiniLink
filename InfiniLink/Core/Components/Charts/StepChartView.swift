//
//  StepChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/11/25.
//

import SwiftUI
import Charts

struct StepChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

struct StepChartView: View {
    @ObservedObject var chartManager = ChartManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    @State private var showSelectionBar = false
    @State private var offset = 0.0
    @State private var selectedDate = Date()
    @State private var selectedSteps = 0
    
    func data() -> [StepChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
        
        // Right now we're only showing a week of data
        
        let daysInWeek = 7
        var filledData: [StepChartDataPoint] = []
        
        let rawPoints = chartManager.stepPoints().compactMap { record -> StepChartDataPoint? in
            guard let timestamp = record.timestamp else { return nil }
            return StepChartDataPoint(date: calendar.startOfDay(for: timestamp), steps: Int(record.steps))
        }
        
        let groupedPoints = Dictionary(grouping: rawPoints, by: { $0.date })
            .mapValues { $0.reduce(0) { $0 + $1.steps } }
        
        for i in 0..<daysInWeek {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let steps = groupedPoints[date] ?? 0
                filledData.append(StepChartDataPoint(date: date, steps: steps))
            }
        }
        
        return filledData
    }
    
    func header() -> some View {
        VStack(alignment: .leading) {
            Text(data().count > 1 ? showSelectionBar ? "Total" : "Average" : " ")
            Text({
                if showSelectionBar {
                    return "\(selectedSteps) "
                } else if !data().isEmpty {
                    return "\(data().reduce(0) { $0 + $1.steps }) "
                }
                return "0 "
            }())
                .font(.system(.title, design: .rounded))
                .foregroundColor(.primary)
            + Text("steps")
            Text(showSelectionBar ? "\(selectedDate.formatted(date: .abbreviated, time: .omitted))" : "\(earliestDate.formatted(date: .abbreviated, time: .omitted)) - \(latestDate.formatted(date: .abbreviated, time: .omitted))")
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
        Group {
//            Section {
//                Picker("Range", selection: $stepChartDataSelection) {
//                    Text("D").tag(0)
//                    Text("W").tag(1)
//                    Text("M").tag(2)
//                    Text("6M").tag(3)
//                    Text("Y").tag(4)
//                }
//                .pickerStyle(.segmented)
//                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
//                .listRowBackground(Color.clear)
//            }
            Section(header: header()) {
                Chart {
                    RuleMark(y: .value("Daily Goal", deviceManager.settings.stepsGoal))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    ForEach(data(), id: \.date) {
                        BarMark(
                            x: .value("Date", $0.date, unit: .weekday),
                            y: .value("Steps", $0.steps)
                        )
                        .foregroundStyle(.blue)
                        .opacity(!showSelectionBar || selectedDate.formatted(.dateTime.dayOfYear()) == $0.date.formatted(.dateTime.dayOfYear()) ? 1 : 0.5)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .foregroundStyle(Color.gray)
                            .frame(width: 2, height: geo.size.height * 0.925)
                            .opacity(showSelectionBar ? 1 : 0)
                            .offset(x: offset)
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        showSelectionBar = true
                                        
                                        let origin = geo[proxy.plotAreaFrame].origin
                                        let location = CGPoint(
                                            x: value.location.x - origin.x,
                                            y: value.location.y - origin.y
                                        )
                                        offset = location.x
                                        
                                        let (day, _) = proxy.value(at: location, as: (Date, Int).self) ?? (Date(), 0)
                                        // We compare the formatted dates because the dates are too specific otherwise
                                        let steps = data().first(where: { $0.date.formatted(.dateTime.dayOfYear()) == day.formatted(.dateTime.dayOfYear()) })?.steps ?? 0
                                        
                                        selectedDate = day
                                        selectedSteps = steps
                                    }
                                    .onEnded { _ in
                                        showSelectionBar = false
                                    }
                            )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: data().map({ $0.date })) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 250)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
