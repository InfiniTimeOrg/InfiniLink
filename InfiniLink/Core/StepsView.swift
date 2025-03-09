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
    
    @State private var showInfoAlert = false
    
    @AppStorage("stepChartDataSelection") private var dataSelection = 0
    
    let exerciseCalculator = FitnessCalculator()
    
    func steps() -> Int {
        for stepCount in chartManager.stepPoints() {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: Date()) {
                return Int(stepCount.steps)
            }
        }
        return 0
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: "\(steps())", subtitle: String(deviceManager.settings.stepsGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            let units = personalizationController.units == .imperial ? "mi" : "km"
                            let distance = exerciseCalculator.calculateDistance(steps: steps())
                            let stepsPerUnit = exerciseCalculator.stepsPerUnit()
                            
                            DetailHeaderSubItemView(title: "Distance",
                                                    value: String(format: "%.2f", distance),
                                                    unit: units,
                                                    icon: ("ruler", Color.blue))
                            DetailHeaderSubItemView(title: "Kcal",
                                                    value: "\(exerciseCalculator.calculateCaloriesBurned(steps: steps()))",
                                                    icon: ("flame", Color.orange))
                            DetailHeaderSubItemView(title: "Total time",
                                                    value: exerciseCalculator.secondsFormatted(seconds: exerciseCalculator.secondsForDistance(distance: distance)),
                                                    icon: ("stopwatch", Color.primary))
                            DetailHeaderSubItemView(title: "SPM",
                                                    value: String(stepsPerUnit),
                                                    icon: ("shoeprints.fill", Color.blue)) {
                                showInfoAlert = true
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                StepChartView()
                StepCalendarView()
            }
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showInfoAlert) {
            Alert(title: Text("Steps Per Minute"), message: Text("SPM stands for steps per minute and measures how many steps you take for each minute of walking."), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    StepsView()
}
