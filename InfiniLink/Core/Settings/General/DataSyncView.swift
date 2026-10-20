//
//  DataSyncView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct DataSyncView: View {
    var body: some View {
        List {
            Section(footer: Text("Sync activity data from your watch to Apple Health.")) {
                NavigationLink("Apple Health") {
                    AppleHealthSyncView()
                }
            }
        }
        .navigationTitle("Data Sync")
    }
}

struct AppleHealthSyncView: View {
    @AppStorage("syncToAppleHealth") private var syncToAppleHealth = true
    @AppStorage("syncStepsToAppleHealth") private var syncSteps = true
    @AppStorage("syncHeartRateToAppleHealth") private var syncHeartRate = true
    @AppStorage("syncCaloriesToAppleHealth") private var syncCalories = true
    @AppStorage("syncExerciseToAppleHealth") private var syncExercise = true
    @AppStorage("syncSleepToAppleHealth") private var syncSleep = true
    @AppStorage("fillStepsFromAppleHealth") private var fillSteps = true

    var body: some View {
        List {
            Section {
                Toggle("Enabled", isOn: $syncToAppleHealth)
            }
            Section {
                Toggle("Steps", isOn: $syncSteps)
                Toggle("Heart Rate", isOn: $syncHeartRate)
                Toggle("Calories", isOn: $syncCalories)
                Toggle("Exercise", isOn: $syncExercise)
                if SleepManager.shared.isSupported {
                    Toggle("Sleep", isOn: $syncSleep)
                }
            } header: {
                Text("Synced Data")
            } footer: {
                Text("Turn off any data you don't want written to Apple Health.")
            }
            .disabled(!syncToAppleHealth)
            Section {
                Toggle("Fill Missing Step Days", isOn: $fillSteps)
            } footer: {
                Text("Use steps from your iPhone and other sources in Apple Health for days your watch wasn't connected.")
            }
        }
        .navigationTitle("Apple Health")
    }
}

#Preview {
    DataSyncView()
}
