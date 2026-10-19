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
    @ObservedObject var stepCountManager = StepCountManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    @State private var rawSelectedDate: Date?
    @State private var points = [StepChartDataPoint]()
    @State private var streak = 0
    
    let fitnessCalculator = FitnessCalculator()
    
    func stepChartPoints() -> [StepChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
        
        var filledData: [StepChartDataPoint] = []
        
        let rawPoints = chartManager.stepPoints(predicate: chartManager.weekPredicate).compactMap { record -> StepChartDataPoint? in
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
    
    private func loadStreak() {
        guard let deviceId = DeviceManager.shared.pairedDeviceID else { return }
        
        HealthTrends().stepGoalStreak(deviceId: deviceId, goal: stepCountManager.stepGoal) { streak in
            self.streak = streak
        }
    }
    
    var earliestDate: Date {
        points.compactMap({ $0.date }).min() ?? Date()
    }
    var latestDate: Date {
        points.compactMap({ $0.date }).max() ?? Date()
    }
    var steps: Int {
        Int(chartManager.stepsToday()?.steps ?? 0)
    }
    
    private var selectedPoint: StepChartDataPoint? {
        guard let rawSelectedDate else { return nil }
        return points.first { Calendar.current.isDate($0.date, inSameDayAs: rawSelectedDate) }
    }
    
    func chart() -> some View {
        var chart: some View {
            Chart {
                RuleMark(y: .value("Daily Goal", stepCountManager.stepGoal))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4]))
                if let selectedPoint {
                    RuleMark(x: .value("Selected", selectedPoint.date, unit: .weekday))
                        .foregroundStyle(Color.gray)
                }
                ForEach(points, id: \.date) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .weekday),
                        y: .value("Steps", point.steps)
                    )
                    .foregroundStyle(.blue)
                    .opacity(selectedPoint == nil || selectedPoint?.id == point.id ? 1 : 0.5)
                }
            }
            .chartXAxis {
                AxisMarks(values: points.map({ $0.date })) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
        }
        
        return Group {
            if #available(iOS 17, *) {
                chart
                    .chartXSelection(value: $rawSelectedDate)
            } else {
                chart
            }
        }
    }
    
    var body: some View {
        Group {
            Section {
                chart()
                    .frame(height: 280)
            } header: {
                VStack(alignment: .leading) {
                    if points.count > 1 {
                        Text(selectedPoint != nil ? "Total" : "Average")
                            .fontWeight(.regular)
                    }
                    Text(selectedPoint?.steps ?? (points.isEmpty ? 0 : points.reduce(0) { $0 + $1.steps } / points.count), format: .number)
                        .font(.system(size: 28))
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                    + Text(" steps")
                    Text(selectedPoint.map { "\($0.date.formatted(date: .abbreviated, time: .omitted))" } ?? "\(earliestDate.formatted(date: .abbreviated, time: .omitted)) - \(latestDate.formatted(date: .abbreviated, time: .omitted))")
                    if streak > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .imageScale(.large)
                                .foregroundStyle(.orange)
                            Text("You're on a ") +
                            (Text(streak, format: .number) + Text("-day"))
                                .foregroundColor(.orange)
                                .fontWeight(.bold) +
                            Text(" step goal streak!")
                        }
                        .foregroundStyle(Color.primary)
                        .font(.system(size: 15))
                        .padding(.vertical, 9)
                    }
                }
                .fontWeight(.semibold)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0))
            Section {
                if steps >= stepCountManager.stepGoal {
                    Text("Great job, you reached your daily step goal today! You've walked \(fitnessCalculator.calculateDistance(steps: steps), format: .number.precision(.fractionLength(2))) \(personalizationController.units == .imperial ? "miles" : "kilometers") and burned around \(fitnessCalculator.energyString(kcal: Double(fitnessCalculator.calculateCaloriesBurned(steps: steps)))).")
                } else {
                    let stepsRemaining = stepCountManager.stepGoal - steps
                    let distanceRemaining = fitnessCalculator.calculateDistance(steps: stepsRemaining)
                    let caloriesRemaining = fitnessCalculator.calculateCaloriesBurned(steps: stepsRemaining)
                    let timeRemaining = fitnessCalculator.secondsFormatted(seconds: fitnessCalculator.secondsForDistance(distance: distanceRemaining), full: true)
                    
                    if stepsRemaining <= 100 {
                        Text("You're so close! Just about a minute left and only \(stepsRemaining) steps to reach your goal!")
                    } else if stepsRemaining <= 1000 {
                        Text("You're almost there! A quick \(distanceRemaining, format: .number.precision(.fractionLength(1))) \(personalizationController.units == .imperial ? "mile" : "km") walk should get you to your goal. It should only take you about \(timeRemaining).")
                    } else if stepsRemaining <= 2500 {
                        Text("You're making great progress! You have about \(distanceRemaining, format: .number.precision(.fractionLength(1))) \(personalizationController.units == .imperial ? "miles" : "kilometers") to walk. At your current pace, you'll hit your goal in \(timeRemaining).")
                    } else {
                        Text("You're \(stepsRemaining) steps away from your goal, which is about \(distanceRemaining, format: .number.precision(.fractionLength(1))) \(personalizationController.units == .imperial ? "miles" : "kilometers"). Once you complete your goal, you'll have burned \(fitnessCalculator.energyString(kcal: Double(caloriesRemaining))) and walked for about \(timeRemaining)!")
                    }
                }
            }
        }
        .onAppear {
            points = stepChartPoints()
            loadStreak()
        }
        .onChange(of: steps >= stepCountManager.stepGoal) { _ in
            loadStreak()
        }
        .onChange(of: bleManager.stepCount) { _ in
            points = stepChartPoints()
        }
        .onChange(of: selectedPoint?.date) { newValue in
            guard newValue != nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
