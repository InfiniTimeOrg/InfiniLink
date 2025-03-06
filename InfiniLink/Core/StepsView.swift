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
    
    func steps(for date: Date) -> Int {
        for stepCount in chartManager.stepPoints() {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
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
                    DetailHeaderView(Header(title: "\(steps(for: Date()))", subtitle: String(deviceManager.settings.stepsGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                        HStack {
                            DetailHeaderSubItemView(title: "Dis",
                                                    value: String(format: "%.2f", exerciseCalculator.calculateDistance(steps: steps(for: Date()))),
                                                    unit: personalizationController.units == .imperial ? "mi" : "km")
                            DetailHeaderSubItemView(title: "Kcal", value: String(format: "%.1f", exerciseCalculator.calculateCaloriesBurned(steps: steps(for: Date()))))
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
