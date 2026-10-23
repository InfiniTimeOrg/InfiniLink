//
//  GoalsNotificationsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 14.10.26.
//

import SwiftUI

struct GoalsNotificationsView: View {
    var body: some View {
        List {
            GoalsNotificationSections()
        }
        .navigationTitle("Daily Goals")
    }
}

struct GoalsNotificationSections: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared

    var isSetup = false

    var body: some View {
        Section(header: isSetup ? Text("Daily Goals") : nil, footer: Text("Get notified when you reach your step goal, keep a streak going, or take more steps than ever before.")) {
            Toggle("Step Goal", isOn: $settingsManager.settings.goalSettings.stepReminderEnabled.animation())
            if settingsManager.settings.goalSettings.stepReminderEnabled {
                Toggle("Streaks", isOn: $settingsManager.settings.goalSettings.streakReminderEnabled)
            }
            Toggle("Halfway to Goal", isOn: $settingsManager.settings.goalSettings.halfwayReminderEnabled)
            Toggle("New Records", isOn: $settingsManager.settings.goalSettings.recordReminderEnabled)
        }
    }
}

#Preview {
    GoalsNotificationsView()
}
