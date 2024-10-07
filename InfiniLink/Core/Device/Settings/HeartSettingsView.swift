//
//  HeartSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct HeartSettingsView: View {
    @AppStorage("backgroundHRMMeasurements") var backgroundHRMMeasurements = false
    @AppStorage("filterHeartRateData") var filterHeartRateData = true
    
    var body: some View {
        List {
            // TODO: remove before production
            Section(footer: Text("Intelligently monitor your heart rate 24 hours a day. This feature will shorten your watch's battery life.")) {
                Toggle("Background Measurements", isOn: $backgroundHRMMeasurements)
            }
            Section(footer: Text("Filter inconsistent data from your heart rate measurements.")) {
                Toggle("Filter Data", isOn: $filterHeartRateData)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    HeartSettingsView()
}
