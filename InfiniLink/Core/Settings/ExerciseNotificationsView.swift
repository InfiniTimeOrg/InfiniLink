//
//  ExerciseNotificationsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 14.10.26.
//

import SwiftUI
 
struct ExerciseNotificationsView: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var body: some View {
        List {
            Section(footer: Text("Notify your watch when a workout starts, pauses, resumes, ends, and on each completed mile or kilometer.")) {
                Toggle("Watch Haptics", isOn: $settingsManager.settings.exerciseSettings.watchHapticsEnabled)
            }
        }
        .navigationTitle("Exercise Notifications")
    }
}
 
#Preview {
    ExerciseNotificationsView()
}
