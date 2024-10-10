//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import SwiftUICharts

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
    let exerciseCalculator = FitnessCalculator()
    
    func steps(for date: Date) -> String {
        for stepCount in existingStepCounts {
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
                DetailHeaderView(Header(title: steps(for: Date()), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                    HStack {
                        DetailHeaderSubItemView(title: "Dis",
                                                value: String(format: "%.2f",
                                                              exerciseCalculator.metersToMiles(meters: exerciseCalculator.calculateDistance(steps: bleManager.stepCount))),
                                                unit: "mi")
                        DetailHeaderSubItemView(title: "Kcal", value: String(format: "%.1f", exerciseCalculator.calculateCaloriesBurned(steps: bleManager.stepCount)))
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Steps")
        .toolbar {
            
        }
    }
}

#Preview {
    StepsView()
}
