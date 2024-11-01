//
//  GoalsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

enum StepsGoal: Int, CaseIterable, Identifiable {
    case thousand = 1000
    case twoThousand = 2000
    case threeThousand = 3000
    case fourThousand = 4000
    case fiveThousand = 5000
    case sixThousand = 6000
    case sevenThousand = 7000
    case eightThousand = 8000
    case nineThousand = 9000
    case tenThousand = 10000
    case fifteenThousand = 15000
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
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var stepsGoal = Int(DeviceManager.shared.settings.stepsGoal)
    
    @AppStorage("caloriesGoal") var caloriesGoal = 400
    @AppStorage("exerciseTimeGoal") var exerciseTime: ExerciseTimeGoal = .hour
    
    var body: some View {
        List {
            Section(footer: Text("Set the daily goals for your fitness goals.")) {
                /*
                 TODO: properly implement settings writing
                Picker("Steps", selection: $stepsGoal) {
                    ForEach(StepsGoal.allCases, id: \.self) { goal in
                        Text("\(goal.rawValue)").tag(goal.rawValue)
                    }
                }
                .disabled(bleManager.blefsTransfer == nil) // Explain to user why disabled?
                 */
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
        .onChange(of: stepsGoal) { stepsGoal in
            BLEFSHandler.shared.setStepsGoal(&deviceManager.settings, stepsGoal: UInt32(stepsGoal))
        }
    }
}

#Preview {
    GoalsSettingsView()
}
