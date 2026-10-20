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
                Section {
                    NavigationLink {
                        ExerciseNotificationsView()
                    } label: {
                        ListRowView(title: "Exercise Notifications", icon: "figure.run", iconColor: .orange)
                    }
                    NavigationLink {
                        HealthNotificationsView()
                    } label: {
                        ListRowView(title: "Health Notifications", icon: "heart.fill", iconColor: .red)
                    }
                    NavigationLink {
                        GoalsNotificationsView()
                    } label: {
                        ListRowView(title: "Daily Goals", icon: "shoeprints.fill", iconColor: .blue)
                    }
                    NavigationLink {
                        BatterySettingsView()
                    } label: {
                        ListRowView(title: "Battery Notifications", icon: "battery.100percent", iconColor: .green)
                    }
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
        .onAppear {
            notificationManager.refreshAuthorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            notificationManager.refreshAuthorizationStatus()
        }
    }
}

#Preview {
    NotificationsSettingsView()
}
