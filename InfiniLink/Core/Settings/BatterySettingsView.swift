//
//  BatterySettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct BatterySettingsView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var settingsManager = NotificationSettingsManager.shared
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(format: "%.0f", bleManager.batteryLevel), units: "%", icon: {
                        if bleManager.batteryLevel > 75 {
                            return "battery.100percent"
                        } else if bleManager.batteryLevel > 50 {
                            return "battery.75percent"
                        } else if bleManager.batteryLevel > 25 {
                            return "battery.50percent"
                        } else if bleManager.batteryLevel == 0 {
                            return "battery.0percent"
                        } else {
                            return "battery.25percent"
                        }
                    }(), accent: bleManager.batteryLevel.batteryColor), width: geo.size.width) {
                        Color.clear
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                BatteryChartView()
                Section {
                    NavigationLink {
                        BatteryHealthView()
                    } label: {
                        Text("Battery Health")
                    }
                }
                Group {
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
                            Toggle("Notify at Custom Percentage", isOn: $settingsManager.settings.batterySettings.customNotificationEnabled)
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
                }
            }
            .navigationTitle("Battery")
        }
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
