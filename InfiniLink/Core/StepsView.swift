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
    
    func formattedSteps(_ steps: Int) -> String {
        Formatter.localizedDecimal.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    func steps() -> Int {
        let stepCount = chartManager.stepsToday()
        if let stepCount = stepCount {
            return Int(stepCount.steps)
        }
        return 0
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: "\(formattedSteps(steps()))", subtitle: formattedSteps(Int(deviceManager.settings.stepsGoal)), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                        StepMenuItemView(steps: steps())
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                StepChartView()
                StepCalendarView(geo: geo)
            }
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                StepSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct StepMenuItemView: View {
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    private let exerciseCalculator = FitnessCalculator()
    
    let steps: Int
    
    @State private var showInfoAlert = false
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
            let units = personalizationController.units == .imperial ? "mi" : "km"
            let distance = exerciseCalculator.calculateDistance(steps: steps)
            let stepsPerMinute = exerciseCalculator.stepsPerMinute(steps: steps)
            
            DetailHeaderSubItemView(title: "Distance",
                                    value: String(format: "%.2f", distance),
                                    unit: units,
                                    icon: ("ruler", Color.blue))
            DetailHeaderSubItemView(title: "Kcal",
                                    value: "\(exerciseCalculator.calculateCaloriesBurned(steps: steps))",
                                    icon: ("flame", Color.orange))
            DetailHeaderSubItemView(title: "Total time",
                                    value: exerciseCalculator.secondsFormatted(seconds: exerciseCalculator.secondsForDistance(distance: distance)),
                                    icon: ("stopwatch", Color.primary))
            DetailHeaderSubItemView(title: "SPM",
                                    value: String(stepsPerMinute),
                                    icon: ("shoeprints.fill", Color.blue)) {
                showInfoAlert = true
            }
        }
        .alert(isPresented: $showInfoAlert) {
            Alert(title: Text("Steps Per Minute"), message: Text("SPM stands for steps per minute and measures how many steps you take for each minute of walking."), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    StepsView()
}
