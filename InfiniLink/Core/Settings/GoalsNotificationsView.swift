//
//  GoalsNotificationsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 14.10.26.
//

import SwiftUI
 
struct GoalsNotificationsView: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var body: some View {
        List {
            Section(footer: Text("Get notified when you reach your daily fitness goals.")) {
                Toggle("Steps", isOn: $settingsManager.settings.goalSettings.stepReminderEnabled)
            }
        }
        .navigationTitle("Daily Goals")
    }
}
 
#Preview {
    GoalsNotificationsView()
}
