//
//  GoalsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct GoalsSettingsView: View {
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    @AppStorage("exercizeTimeGoal") var exerciseTime = 1800
    
    var body: some View {
        List {
            Section(footer: Text("Set the daily goals for your fitness goals.")) {
                // FIXME: compensate for differences in data handling
                Picker("Steps", selection: $stepCountGoal) {
                    ForEach(2...30, id: \.self) { index in
                        Text(String(index * 1000))
                    }
                }
                Picker("Calories", selection: $stepCountGoal) {
                    ForEach(1...50, id: \.self) { index in
                        Text(String(index * 100))
                    }
                }
                Picker("Exercise Time", selection: $stepCountGoal) {
                    ForEach(1...6, id: \.self) { index in
                        Text(String(index * 30) + " mins")
                    }
                }
            }
        }
        .navigationTitle("Daily Goals")
    }
}

#Preview {
    GoalsSettingsView()
}
