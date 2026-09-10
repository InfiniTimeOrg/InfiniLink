//
//  ExerciseSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/9/26.
//

import SwiftUI

struct ExerciseSettingsView: View {
    @AppStorage("autoPauseExercise") var autoPauseExercise = false

    var body: some View {
        List {
            Section(footer: Text("Automatically pause running and walking workouts when you stop moving, and resume when you start again.")) {
                Toggle("Auto-Pause", isOn: $autoPauseExercise)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    ExerciseSettingsView()
}
