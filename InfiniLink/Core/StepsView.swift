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
    
    @AppStorage("stepChartDataSelection") private var dataSelection = 0
    
    let exerciseCalculator = FitnessCalculator()
    
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
                StepChartView()
            }
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    StepsView()
}
