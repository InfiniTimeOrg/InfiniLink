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
    
    @FetchRequest var stepCounts: FetchedResults<StepCounts>
    
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

    init() {
        _stepCounts = FetchRequest(
            entity: StepCounts.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)],
            predicate: NSPredicate(format: "deviceId == %@", BLEManager.shared.pairedDeviceID ?? "")
        )
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: "\(steps())", subtitle: String(deviceManager.settings.stepsGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            let unitsFull = personalizationController.units == .imperial ? "mile" : "kilometer"
                            let units = personalizationController.units == .imperial ? "mi" : "km"
                            let distance = exerciseCalculator.calculateDistance(steps: steps())
                            let stepsPerUnit = exerciseCalculator.stepsPerUnit(steps: steps())
                            
                            DetailHeaderSubItemView(title: "Distance",
                                                    value: String(format: "%.2f", distance),
                                                    unit: units,
                                                    icon: ("ruler", Color.blue))
                            DetailHeaderSubItemView(title: "Kcal",
                                                    value: String(exerciseCalculator.calculateCaloriesBurned(steps: steps())),
                                                    icon: ("flame", Color.orange))
                            DetailHeaderSubItemView(title: "Minutes per \(unitsFull)",
                                                    value: String(format: "%.1f", exerciseCalculator.minutesForDistance(distance: distance)),
                                                    unit: "min\(distance == 1 ? "" : "s")",
                                                    icon: ("stopwatch", Color.primary))
                            DetailHeaderSubItemView(title: "Steps per \(unitsFull)",
                                                    value: String(stepsPerUnit),
                                                    unit: "step\(stepsPerUnit == 1 ? "" : "s")",
                                                    icon: ("shoeprints.fill", Color.blue))
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
    }
}

#Preview {
    StepsView()
}
