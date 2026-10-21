//
//  ExerciseNotificationsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 14.10.26.
//

import SwiftUI

struct ExerciseNotificationsView: View {
    var body: some View {
        List {
            ExerciseNotificationSections()
        }
        .navigationTitle("Exercise Notifications")
    }
}

struct ExerciseNotificationSections: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared

    var isSetup = false

    var body: some View {
        Section(header: isSetup ? Text("Exercise") : nil, footer: Text("Notify your watch when a workout starts, pauses, resumes, ends, and on each completed mile or kilometer.")) {
            Toggle("Watch Haptics", isOn: $settingsManager.settings.exerciseSettings.watchHapticsEnabled)
        }
    }
}

#Preview {
    ExerciseNotificationsView()
}
