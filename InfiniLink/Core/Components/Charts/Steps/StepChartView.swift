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
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    @State private var showSelectionBar = false
    @State private var offset = 0.0
    @State private var selectedDate = Date()
    @State private var selectedSteps = 0
    
    let fitnessCalculator = FitnessCalculator()
    
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
                let steps = Int(chartManager.stepPoints().last?.steps ?? 0)
                
                if stepCountManager.hasReachedStepGoal {
                    Text("Great job, you reached your daily step goal today! You've walked \(fitnessCalculator.calculateDistance(steps: steps)) \(personalizationController.units == .imperial ? "miles" : "kilometers") and burned around \(fitnessCalculator.calculateCaloriesBurned(steps: steps)) kcal.")
                } else {
                    let stepsRemaining = stepCountManager.stepGoal - steps
                    let distanceRemaining = fitnessCalculator.calculateDistance(steps: stepsRemaining)
                    let caloriesRemaining = fitnessCalculator.calculateCaloriesBurned(steps: stepsRemaining)
                    let timeRemaining = fitnessCalculator.secondsFormatted(seconds: Int(fitnessCalculator.secondsForDistance(distance: distanceRemaining)), full: true)
                    
                    if stepsRemaining <= 1000 {
                        Text("You're almost there! A quick \(String(format: "%.1f", distanceRemaining)) \(personalizationController.units == .imperial ? "mile" : "km") walk will get you to your goal. It should only take you about \(timeRemaining).")
                    } else if stepsRemaining <= 2500 {
                        Text("You're making great progress! You have about \(String(format: "%.1f", distanceRemaining)) \(personalizationController.units == .imperial ? "miles" : "kilometers") to walk. At your current pace, you'll hit your goal in \(timeRemaining).")
                    } else {
                        Text("You're \(stepsRemaining) steps away from your goal, which is about \(String(format: "%.1f", distanceRemaining)) \(personalizationController.units == .imperial ? "miles" : "kilometers"). Once you complete your goal, you'll have burned \(caloriesRemaining) kcal and walked for about \(timeRemaining)!")
                    }
                }
            }
        }
    }
}
