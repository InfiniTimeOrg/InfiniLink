//
//  HealthNotificationsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 14.10.26.
//

import SwiftUI
 
struct HealthNotificationsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var body: some View {
        List {
            Section(footer: Text("Receive a reminder to drink water for the set amount of times a day.")) {
                Toggle("Water Reminder", isOn: $settingsManager.settings.waterReminderEnabled)
                if settingsManager.settings.waterReminderEnabled {
                    Picker("Interval", selection: $settingsManager.settings.waterReminderAmount) {
                        ForEach(0..<9, id: \.self) { amount in
                            Text(amount == 0 ? "1 time" : "\(amount + 1, format: .number) times")
                        }
                    }
                }
            }
            Section(footer: Text("Get a notification when your heart rate goes above or below the specified range.")) {
                Toggle("Heart Range Notifications", isOn: $settingsManager.settings.heartSettings.rangeReminderEnabled)
                if settingsManager.settings.heartSettings.rangeReminderEnabled {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text(settingsManager.settings.heartSettings.minRange, format: .number)
                        Stepper("\(settingsManager.settings.heartSettings.minRange)", value: $settingsManager.settings.heartSettings.minRange, in: 40...(settingsManager.settings.heartSettings.maxRange - 1), step: 1)
                            .fontWeight(.semibold)
                            .labelsHidden()
                    }
                    HStack {
                        Text("Maximum")
                        Spacer()
                        Text(settingsManager.settings.heartSettings.maxRange, format: .number)
                        Stepper("\(settingsManager.settings.heartSettings.maxRange)", value: $settingsManager.settings.heartSettings.maxRange, in: (settingsManager.settings.heartSettings.minRange + 1)...220, step: 1)
                            .fontWeight(.semibold)
                            .labelsHidden()
                    }
                }
            }
        }
        .navigationTitle("Health Notifications")
        .onChange(of: settingsManager.settings.waterReminderAmount) { _ in
            notificationManager.setWaterRemindersPerDay()
        }
    }
}
 
#Preview {
    HealthNotificationsView()
}
 
