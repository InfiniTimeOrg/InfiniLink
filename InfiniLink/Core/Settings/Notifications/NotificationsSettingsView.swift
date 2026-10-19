//
//  NotificationsSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/4/24.
//

import SwiftUI

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
                NotificationSettingsSections()
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
        .onAppear {
            notificationManager.refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            notificationManager.refreshAuthorizationStatus()
        }
        .onChange(of: settingsManager.settings.waterReminderAmount) { _ in
            notificationManager.setWaterRemindersPerDay()
        }
    }
}

// Shared with setup so both list the same notifications
struct NotificationSettingsSections: View {
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var isSetup = false
    
    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour % 24, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
    
    private func footer(_ text: LocalizedStringKey, customizable: Bool = false) -> Text {
        isSetup && customizable ? Text(text) + Text(" You can customize this in notification settings.") : Text(text)
    }
    
    var body: some View {
        Section(header: Text("Health"), footer: footer("Receive a reminder to drink water for the set amount of times a day.", customizable: true)) {
            Toggle("Water Reminder", isOn: $settingsManager.settings.waterReminderEnabled)
            if !isSetup && settingsManager.settings.waterReminderEnabled {
                Picker("Interval", selection: $settingsManager.settings.waterReminderAmount) {
                    ForEach(0..<9, id: \.self) { amount in
                        Text(amount == 0 ? "1 time" : "\(amount + 1, format: .number) times")
                    }
                }
            }
        }
        Section(footer: footer("Get a reminder to move when you haven't walked for a while during the set hours.", customizable: true)) {
            Toggle("Inactivity Reminder", isOn: $settingsManager.settings.inactivitySettings.enabled)
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
        Section(footer: footer("Get a notification when your heart rate goes above or below the specified range.", customizable: true)) {
            Toggle("Heart Range Notifications", isOn: $settingsManager.settings.heartSettings.rangeReminderEnabled)
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
        Section(header: Text("Exercise"), footer: Text("Notify your watch when a workout starts, pauses, resumes, ends, and on each completed mile or kilometer.")) {
            Toggle("Watch Haptics", isOn: $settingsManager.settings.exerciseSettings.watchHapticsEnabled)
        }
        Section(header: Text("Daily Goals"), footer: Text("Get notified when you reach your step goal, keep a streak going, or take more steps than ever before.")) {
            Toggle("Step Goal", isOn: $settingsManager.settings.goalSettings.stepReminderEnabled)
            if settingsManager.settings.goalSettings.stepReminderEnabled {
                Toggle("Streaks", isOn: $settingsManager.settings.goalSettings.streakReminderEnabled)
            }
            Toggle("Halfway to Goal", isOn: $settingsManager.settings.goalSettings.halfwayReminderEnabled)
            Toggle("New Records", isOn: $settingsManager.settings.goalSettings.recordReminderEnabled)
        }
    }
}

#Preview {
    NotificationsSettingsView()
}
