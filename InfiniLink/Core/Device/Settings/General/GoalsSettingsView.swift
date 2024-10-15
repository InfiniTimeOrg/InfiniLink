//
//  GoalsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

enum StepsGoal: Int, CaseIterable, Identifiable {
    case fivehundred = 500
    case thousand = 1000
    case fiveThousand = 5000
    case tenThousand = 10000
    case twentyThousand = 20000
    
    var id: Int { rawValue }
}

enum ExerciseTimeGoal: Int, CaseIterable, Identifiable {
    case halfHour = 1800
    case hour = 3600
    case hourAndHalf = 5400
    case twoHours = 7200
    case twoHoursAndHalf = 9000
    case threeHours = 10800
    
    var id: Int { rawValue }
    
    var description: String {
        "\(rawValue / 60) mins"
    }
}

struct GoalsSettingsView: View {
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    @AppStorage("exerciseTimeGoal") var exerciseTime: ExerciseTimeGoal = .hour
    
    var body: some View {
        List {
            Section(footer: Text("Set the daily goals for your fitness goals.")) {
                Picker("Steps", selection: $stepCountGoal) {
                    ForEach(StepsGoal.allCases, id: \.self) { goal in
                        Text("\(goal.rawValue)").tag(goal.rawValue)
                    }
                }
                Picker("Calories", selection: $caloriesGoal) {
                    ForEach(1...30, id: \.self) { index in
                        Text("\(index * 100)").tag(index * 100)
                    }
                }
                Picker("Exercise Time", selection: $exerciseTime) {
                    ForEach(ExerciseTimeGoal.allCases) { time in
                        Text(time.description).tag(time)
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
