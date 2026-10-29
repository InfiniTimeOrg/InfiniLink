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
            HealthNotificationSections()
        }
        .navigationTitle("Health Notifications")
        .onChange(of: settingsManager.settings.waterReminderAmount) { _ in
            notificationManager.setWaterRemindersPerDay()
        }
    }
}

// Shared with setup, which hides the detail controls
struct HealthNotificationSections: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared

    var isSetup = false

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour % 24, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }

    private func footer(_ text: LocalizedStringKey) -> Text {
        isSetup ? Text(text) + Text(" You can customize this in notification settings.") : Text(text)
    }

    var body: some View {
        Section(header: isSetup ? Text("Health") : nil, footer: footer("Receive a reminder to drink water for the set amount of times a day.")) {
            Toggle("Water Reminder", isOn: $settingsManager.settings.waterReminderEnabled.animation())
            if !isSetup && settingsManager.settings.waterReminderEnabled {
                Picker("Interval", selection: $settingsManager.settings.waterReminderAmount) {
                    ForEach(0..<9, id: \.self) { amount in
                        Text(amount == 0 ? "1 time" : "\(amount + 1, format: .number) times")
                    }
                }
            }
        }
        Section(footer: footer("Get a reminder to move when you haven't walked for a while during the set hours.")) {
            Toggle("Inactivity Reminder", isOn: $settingsManager.settings.inactivitySettings.enabled.animation())
            if !isSetup && settingsManager.settings.inactivitySettings.enabled {
                Picker("Remind After", selection: $settingsManager.settings.inactivitySettings.minutes) {
                    ForEach([30, 45, 60, 90, 120], id: \.self) { minutes in
                        Text(Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))).tag(minutes)
                    }
                }
                Picker("From", selection: $settingsManager.settings.inactivitySettings.startHour) {
                    ForEach(0..<settingsManager.settings.inactivitySettings.endHour, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                Picker("Until", selection: $settingsManager.settings.inactivitySettings.endHour) {
                    ForEach((settingsManager.settings.inactivitySettings.startHour + 1)...24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
            }
        }
        if !isSetup && SleepManager.shared.isSupported {
            Section(footer: Text("Get a reminder to get ready for bed before the bedtime in your sleep schedule.")) {
                Toggle("Bedtime Reminder", isOn: $settingsManager.settings.bedtimeSettings.enabled.animation())
                if settingsManager.settings.bedtimeSettings.enabled {
                    Picker("Remind Me", selection: $settingsManager.settings.bedtimeSettings.minutesBefore) {
                        ForEach([0, 15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                            if minutes == 0 {
                                Text("At Bedtime").tag(minutes)
                            } else {
                                Text("\(Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))) before").tag(minutes)
                            }
                        }
                    }
                }
            }
        }
        Section(footer: footer("Get a notification when your heart rate goes above or below the specified range.")) {
            Toggle("Heart Range Notifications", isOn: $settingsManager.settings.heartSettings.rangeReminderEnabled.animation())
            if !isSetup && settingsManager.settings.heartSettings.rangeReminderEnabled {
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
}

#Preview {
    HealthNotificationsView()
}

