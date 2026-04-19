//
//  BatterySettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct BatterySettingsView: View {
    @AppStorage("watchNotifications") var watchNotifications = true
    @AppStorage("sendLowBatteryNotification") var sendLowBatteryNotification = true
    @AppStorage("sendFullBatteryNotification") var sendFullBatteryNotification = true
    @AppStorage("sendLowBatteryNotificationToiPhone") var sendLowBatteryNotificationToiPhone = true
    @AppStorage("sendLowBatteryNotificationToWatch") var sendLowBatteryNotificationToWatch = true
    @AppStorage("sendCustomBatteryNotification") var sendCustomBatteryNotification = false
    @AppStorage("customBatteryNotificationPercentage") var customBatteryNotificationPercentage = 50.0
    
    @ObservedObject var bleManager = BLEManager.shared
    
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
                    }(), accent: {
                        if bleManager.batteryLevel > 20 {
                            return Color.green
                        } else if bleManager.batteryLevel > 10 {
                            return Color.orange
                        } else if bleManager.batteryLevel == 0 {
                            return Color.gray
                        } else {
                            return Color.red
                        }
                    }()), width: geo.size.width) {
                        Color.clear
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                Group {
                    if watchNotifications {
                        Section(footer: Text(bleManager.ancsAuthorized ? "You can't disable watch notifications while iPhone notifications are on and ANCS is enabled." : "Send a notification to your devices when your watch is low on battery.")) {
                            Toggle("Notify on Low Battery", isOn: $sendLowBatteryNotification)
                            if sendLowBatteryNotification {
                                Toggle("Send to iPhone", isOn: $sendLowBatteryNotificationToiPhone)
                                Toggle(isOn: bleManager.ancsAuthorized ? .constant(true) : $sendLowBatteryNotificationToWatch) { // Notifications will already send to watch when iPhone notifications are on and ANCS is enabled
                                    VStack(alignment: .leading) {
                                        Text("Send to Watch")
                                        if bleManager.ancsAuthorized {
                                            Text("You can't disable watch notifications while iPhone notifications are on and ANCS is enabled.")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .disabled(bleManager.ancsAuthorized && sendLowBatteryNotificationToiPhone)
                            }
                        }
                        Section(footer: Text("Send a notification to your iPhone when your watch's battery level reaches full capacity.")) {
                            Toggle("Notify when Fully Charged", isOn: $sendFullBatteryNotification)
                        }
                        Section(footer: sendCustomBatteryNotification ? AnyView(Text("You will be notified when your watch's battery level reaches \(Int(customBatteryNotificationPercentage))%.")) : AnyView(EmptyView())) {
                            Toggle("Notify at Custom Percentage", isOn: $sendCustomBatteryNotification)
                            if sendCustomBatteryNotification {
                                VStack {
                                    HStack {
                                        Text("0%").font(.caption).foregroundStyle(.secondary)
                                        Slider(value: $customBatteryNotificationPercentage, in: 0...95, step: 5)
                                        Text("95%").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        NavigationLink {
                            NotificationsSettingsView()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 32).weight(.medium))
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Watch Notifications Disabled")
                                        .foregroundStyle(Color.primary)
                                        .fontWeight(.bold)
                                    Text("To customize battery notifications, you need to allow watch notifications in notification settings.")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Battery")
        }
    }
}

#Preview {
    NavigationStack {
        BatterySettingsView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
