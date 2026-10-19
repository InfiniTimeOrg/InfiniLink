//
//  HeartSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct HeartSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared

    @AppStorage("backgroundHRMMeasurements") var backgroundHRMMeasurements = false
    @AppStorage("filterHeartRateData") var filterHeartRateData = true
    @AppStorage("heartPointMarkMode") var heartPointMarkMode = "average"

    @StateObject private var editor = WatchSettingsEditor()

    private let intervals: [(LocalizedStringKey, UInt16?)] = [
        ("Off", nil), ("Continuous", 0), ("30 seconds", 30), ("1 minute", 60), ("5 minutes", 300), ("10 minutes", 600), ("30 minutes", 1800)
    ]

    var body: some View {
        List {
            Section(footer: Text("Filter inconsistent data from your heart rate measurements.")) {
                Toggle("Filter Values", isOn: $filterHeartRateData)
            }
            Section(footer: Text("Choose how the point mark on the heart rate chart is calculated.")) {
                Picker("Point Mark", selection: $heartPointMarkMode) {
                    Text("Average").tag("average")
                    Text("Median").tag("median")
                }
                .pickerStyle(.menu)
            }
            // Saving defaults replaces everything, so only allow that from Customization
            if let file = editor.file, file.supportsBackgroundHeartRate, !editor.usingDefaults {
                Section {
                    Picker("Background Measurements", selection: Binding(
                        get: { file.heartRateBackgroundPeriod },
                        set: { editor.file?.heartRateBackgroundPeriod = $0 }
                    )) {
                        ForEach(intervals, id: \.1) { interval in
                            Text(interval.0).tag(interval.1)
                        }
                    }
                    WatchSettingsSaveButton(editor: editor)
                } footer: {
                    Text("How often \(deviceManager.name) measures your heart rate in the background. More frequent measurements use more battery and improve sleep tracking.")
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if editor.file == nil {
                editor.load()
            }
        }
        .modifier(WatchSettingsAlerts(editor: editor, deviceName: deviceManager.name))
    }
}

#Preview {
    HeartSettingsView()
}
