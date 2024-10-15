//
//  GoalsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

enum StepsGoal: Int {
    case fivehundred = 500
}

enum ExerciseTimeGoal: Int {
    case halfHour = 1800
    case hour = 3600
    case hourAndHalf = 5400
    case twoHours = 7200
    case twoHoursAndHalf = 9000
    case threeHours = 10800
    
    static let all: [ExerciseTimeGoal] = [.halfHour, .hour, .hourAndHalf, .twoHours, .twoHoursAndHalf, .threeHours]
}

struct GoalsSettingsView: View {
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    @AppStorage("exerciseTimeGoal") var exerciseTime: ExerciseTimeGoal = .hour
    
    var body: some View {
        List {
            Section(footer: Text("Set the daily goals for your fitness goals.")) {
                Picker("Steps", selection: $stepCountGoal) {
                    ForEach(2...30, id: \.self) { index in
                        Text(String(index * 1000))
                    }
                }
                Picker("Calories", selection: $caloriesGoal) {
                    ForEach(1...50, id: \.self) { index in
                        Text(String(index * 100))
                    }
                }
                Picker("Exercise Time", selection: $exerciseTime) {
                    ForEach(ExerciseTimeGoal.all, id: \.rawValue) { time in
                        Text(String(time.rawValue * 60) + " mins")
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
