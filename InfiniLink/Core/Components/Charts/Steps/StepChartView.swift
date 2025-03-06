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
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var stepCountManager = StepCountManager.shared
    
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    @State private var showSelectionBar = false
    @State private var offset = 0.0
    @State private var selectedDate = Date()
    @State private var selectedSteps = 0
    
    func steps() -> [StepChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
        
        var filledData: [StepChartDataPoint] = []
        
        let rawPoints = chartManager.stepPoints().compactMap { record -> StepChartDataPoint? in
            guard let timestamp = record.timestamp else { return nil }
            // Return each step point as a chart point
            return StepChartDataPoint(date: calendar.startOfDay(for: timestamp), steps: Int(record.steps))
        }
        
        // Make sure any points for the same day are combined into one point
        let groupedPoints = Dictionary(grouping: rawPoints, by: { $0.date })
            .mapValues { $0.reduce(0) { $0 + $1.steps } }
        let daysInWeek = 7
        
        for weekDay in 0..<daysInWeek {
            if let date = calendar.date(byAdding: .day, value: weekDay, to: startOfWeek) {
                let steps = groupedPoints[date] ?? 0
                filledData.append(StepChartDataPoint(date: date, steps: steps))
            }
        }
        
        return filledData
    }
    
    var earliestDate: Date {
        steps().compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        steps().compactMap({ $0.date }).max() ?? Date()
    }
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        Group {
            Section {
                Chart {
                    RuleMark(y: .value("Daily Goal", deviceManager.settings.stepsGoal))
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                    ForEach(steps(), id: \.date) {
                        BarMark(
                            x: .value("Date", $0.date, unit: .weekday),
                            y: .value("Steps", $0.steps)
                        )
                        .foregroundStyle(.blue)
                        .opacity(!showSelectionBar || selectedDate.comparable() == $0.date.comparable() ? 1 : 0.5)
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
                                        let steps = steps().first(where: { $0.date.comparable() == day.comparable() })?.steps ?? 0
                                        
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
                    AxisMarks(values: steps().map({ $0.date })) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .frame(height: 250)
            } header: {
                VStack(alignment: .leading) {
                    Text(steps().count > 1 ? showSelectionBar ? "Total" : "Average" : " ")
                    Text({
                        if showSelectionBar {
                            return "\(selectedSteps) "
                        } else if !steps().isEmpty {
                            return "\(steps().reduce(0) { $0 + $1.steps } / steps().count) "
                        }
                        return "0 "
                    }())
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    + Text("steps")
                    Text(showSelectionBar ? "\(selectedDate.formatted(date: .abbreviated, time: .omitted))" : "\(earliestDate.formatted(date: .abbreviated, time: .omitted)) - \(latestDate.formatted(date: .abbreviated, time: .omitted))")
                }
                .fontWeight(.semibold)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
            Section {
                if stepCountManager.hasReachedStepGoal {
                    Text("Today you reached your daily step goal! Keep it up, and let's see how many more days can you reach it...")
                } else {
                    let encouragementString: String = {
                        if (stepCountManager.stepGoal - bleManager.stepCount) <= 1000 {
                            return "Take a short walk or a start an activity to complete your goal."
                        }
                        return "Complete a few activities to reach your goal."
                    }()
                    
                    Text("You're \(stepCountManager.stepGoal - bleManager.stepCount) steps away your daily step goal! \(encouragementString)")
                }
            }
        }
    }
}
