//
//  SoftwareUpdateSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import SwiftUI

struct SoftwareUpdateSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var autoUpdateManager = AutoUpdateManager.shared

    var body: some View {
        List {
            Section {
                Toggle("Automatic Updates", isOn: $autoUpdateManager.enabled)
            } footer: {
                Text("Install updates once \(deviceManager.name) has been on its charger for an hour at a time you're usually asleep, based on your recent sleep tracking or your sleep schedule.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SoftwareUpdateSettingsView()
    }
}
