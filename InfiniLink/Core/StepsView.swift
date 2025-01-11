//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @AppStorage("stepsChartDataSelection") private var dataSelection = 0
    
    let exerciseCalculator = FitnessCalculator.shared
    
//    func getStepCounts(displayWeek: Date) -> [BarChartDataPoint] {
//        var dataPoints = [BarChartDataPoint]()
//        var calendar = Calendar.autoupdatingCurrent
//        var week = displayWeek
//        
//        calendar.firstWeekday = 1
//        week = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
//        
//        for weekDay in 0...6 {
//            if let day = calendar.date(byAdding: .day, value: weekDay, to: week) {
//                let shortFormatter = DateFormatter()
//                shortFormatter.dateFormat = "EEEEE"
//                
//                let longFormatter = DateFormatter()
//                longFormatter.dateFormat = "EEEE"
//                
//                let color = ColourStyle(colour: .blue)
//                dataPoints.append(BarChartDataPoint(value: 0, xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: day, colour: color))
//                
//                for i in chartManager.stepPoints() {
//                    if calendar.isDate(i.timestamp!, inSameDayAs: day) {
//                        dataPoints[weekDay] = BarChartDataPoint(value: Double(i.steps), xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: i.timestamp!, colour: color)
//                    }
//                }
//            }
//        }
//        
//        return dataPoints
//    }
    func steps(for date: Date) -> String {
        for stepCount in chartManager.stepPoints() {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
                let formattedSteps = NumberFormatter.localizedString(from: NSNumber(value: stepCount.steps), number: .decimal)
                return formattedSteps
            }
        }
        return "0"
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                    Section {
                        DetailHeaderView(Header(title: steps(for: Date()), subtitle: String(deviceManager.settings.stepsGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                            HStack {
                                DetailHeaderSubItemView(title: "Dis",
                                                        value: String(format: "%.2f", exerciseCalculator.calculateDistance(steps: bleManager.stepCount)),
                                                        unit: personalizationController.units == .imperial ? "mi" : "m")
                                DetailHeaderSubItemView(title: "Kcal", value: String(format: "%.1f", exerciseCalculator.calculateCaloriesBurned(steps: bleManager.stepCount)))
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        Picker("Range", selection: $dataSelection) {
                            Text("D").tag(0)
                            Text("W").tag(1)
                            Text("M").tag(2)
                            Text("6M").tag(3)
                            Text("Y").tag(4)
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    StepChartView()
                        .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Steps")
    }
}

#Preview {
    StepsView()
}
