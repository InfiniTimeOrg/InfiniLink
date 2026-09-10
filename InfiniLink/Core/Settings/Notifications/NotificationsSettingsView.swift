//
//  NotificationsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/4/24.
//

import SwiftUI
import EventKit

struct NotificationsSettingsView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared

    @State private var showSendNotificationSheet = false
    
    private let bleWriteManager = BLEWriteManager()
    
    var body: some View {
        List {
            if !notificationManager.canSendHostNotifs {
                Button {
                    UIApplication.shared.open(URL(string: UIApplication.openNotificationSettingsURLString)!)
                } label: {
                    BannerView("Notifications Disabled", "Notifications have been disabled in system settings. To receive notifications on your iPhone, please turn them on.") {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 28).weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            Section {
                Toggle("Enable Notifications", isOn: $settingsManager.settings.watchNotificationsEnabled)
            }
            if settingsManager.settings.watchNotificationsEnabled {
                Section(header: Text("Health"), footer: Text("Receive a reminder to drink water for the set amount of times a day.")) {
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
                Section(header: Text("Exercise"), footer: Text("Notify your watch when a workout starts, pauses, resumes, ends, and on each completed mile or kilometer.")) {
                    Toggle("Watch Haptics", isOn: $settingsManager.settings.exerciseSettings.watchHapticsEnabled)
                }
                Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your daily fitness goals.")) {
                    Toggle("Steps", isOn: $settingsManager.settings.goalSettings.stepReminderEnabled)
                }
                Section {
                    Toggle("Transliterate to ASCII", isOn: $settingsManager.settings.transliterationEnabled)
                } footer: {
                    Text("Convert accented characters to plain text so notifications display correctly.")
                }
                Button("Send Notification") {
                    showSendNotificationSheet = true
                }
                .disabled(bleManager.notifyCharacteristic == nil)
                .sheet(isPresented: $showSendNotificationSheet) {
                    ArbitraryNotificationView()
                }
            }
        }
        .navigationTitle("Notifications")
        .onChange(of: settingsManager.settings.waterReminderAmount) { _ in
            notificationManager.setWaterRemindersPerDay()
        }
    }
}

#Preview {
    NotificationsSettingsView()
}
