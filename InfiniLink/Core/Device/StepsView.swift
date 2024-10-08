//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
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
                DetailHeaderView(Header(title: steps(for: Date()), titleUnits: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                    HStack {
                        DetailHeaderSubItemView(title: "Dis", value: "1mi")
                        DetailHeaderSubItemView(title: "Kcal", value: "186")
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
