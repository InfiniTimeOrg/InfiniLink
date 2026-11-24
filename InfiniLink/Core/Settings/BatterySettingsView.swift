//
//  BatterySettingsView.swift
//  InfiniLink
//
//  Created by Titus Kendzorra on 07.10.2026.
//  Extracted from the original BatterySettingsView.swift (now BatteryView.swift) by Liam Willey
//

import SwiftUI

struct BatterySettingsView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var body: some View {
        List {
            if settingsManager.settings.watchNotificationsEnabled {
                Section(footer: Text("Send a notification to your devices when they reach low battery.")) {
                    NavigationLink {
                        Form {
                            notificationSettings("Watch", "Send a notification to your devices when your watch is low on battery.", $settingsManager.settings.batterySettings.lowBattery.watch)
                            notificationSettings("iPhone", "Send a notification to your devices when your iPhone drops to \(0.2, format: .percent) charge.", $settingsManager.settings.batterySettings.lowBattery.iphone)
                        }
                        .navigationTitle("Low Battery Notifications")
                    } label: {
                        Text("Notify on Low Battery")
                    }
                }
                Section(footer: Text("Send a notification to your devices when they're fully charged.")) {
                    NavigationLink {
                        Form {
                            notificationSettings("Watch", "Send a notification to your devices when your watch's battery level reaches full capacity.", $settingsManager.settings.batterySettings.fullBattery.watch)
                            notificationSettings("iPhone", "Send a notification to your devices when your iPhone's battery level reaches full capacity.", $settingsManager.settings.batterySettings.fullBattery.iphone)
                        }
                        .navigationTitle("Full Battery Notifications")
                    } label: {
                        Text("Notify on Full Battery")
                    }
                }
                Section {
                    Toggle("Notify at Custom Percentage", isOn: $settingsManager.settings.batterySettings.customNotificationEnabled.animation())
                }
                if settingsManager.settings.batterySettings.customNotificationEnabled {
                    HStack {
                        Text(0, format: .percent).font(.caption).foregroundStyle(.secondary)
                        Slider(value: $settingsManager.settings.batterySettings.customNotificationPercentage, in: 0...95, step: 5)
                        Text(0.95, format: .percent.precision(.fractionLength(0))).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if settingsManager.settings.batterySettings.customNotificationEnabled {
                    notificationSettings(nil, "You will be notified when your watch's battery level reaches \(settingsManager.settings.batterySettings.customNotificationPercentage / 100, format: .percent.precision(.fractionLength(0))).", $settingsManager.settings.batterySettings.customNotificationSettings)
                }
                Section(footer: Text("Get a notification on your watch with an estimate of how long the battery will last when it comes off its charger.")) {
                    Toggle("Notify When Unplugged", isOn: $settingsManager.settings.batterySettings.unplugNotificationEnabled)
                }
                Section(footer: Text("Get a reminder an hour before bedtime if your watch might not last the night. Requires a sleep schedule.")) {
                    Toggle("Remind to Charge Before Bed", isOn: $settingsManager.settings.batterySettings.chargeReminderEnabled)
                }
            } else {
                NavigationLink {
                    NotificationsSettingsView()
                } label: {
                    BannerView("Watch Notifications Disabled", "To customize battery notifications, you need to allow notifications in notification settings.") {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 28).weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
            Section(footer: Text("Show your watch's charge on the Lock Screen while it's charging.")) {
                Toggle("Charging Live Activity", isOn: $settingsManager.settings.batterySettings.chargingLiveActivityEnabled)
            }
        }
        .navigationTitle("Settings")
    }
    
    private func notificationSettings(_ title: LocalizedStringKey?, _ footer: LocalizedStringKey?, _ settings: Binding<NotifySettings>) -> some View {
        Group {
            Section(header: title == nil ? AnyView(EmptyView()) : AnyView(Text(title!)), footer: footer == nil ? AnyView(EmptyView()) : AnyView(Text(footer!))) {
                Toggle("Send to iPhone", isOn: settings.sendToiPhone)
                Toggle(isOn: (bleManager.ancsAuthorized && settings.wrappedValue.sendToiPhone) ? .constant(true) : settings.sendToWatch) {
                    VStack(alignment: .leading) {
                        Text("Send to Watch")
                        if bleManager.ancsAuthorized && settings.wrappedValue.sendToiPhone {
                            Text("You can't disable watch notifications while iPhone notifications are on and ANCS is enabled.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(bleManager.ancsAuthorized && settings.wrappedValue.sendToiPhone)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BatterySettingsView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
