//
//  BatterySettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct BatterySettingsView: View {
    @AppStorage("sendLowBatteryNotification") var sendLowBatteryNotification = true
    @AppStorage("sendLowBatteryNotificationToiPhone") var sendLowBatteryNotificationToiPhone = true
    @AppStorage("sendLowBatteryNotificationToWatch") var sendLowBatteryNotificationToWatch = true
    
    var body: some View {
        List {
            Section(footer: Text("Send a notification to your devices when your watch is on low battery.")) {
                Toggle("Notify on Low Battery", isOn: $sendLowBatteryNotification)
            }
            if sendLowBatteryNotification {
                Section {
                    Toggle("Send to iPhone", isOn: $sendLowBatteryNotification)
                    Toggle("Send to Watch", isOn: $sendLowBatteryNotification)
                }
            }
        }
        .navigationTitle("Battery")
    }
}

#Preview {
    BatterySettingsView()
}
