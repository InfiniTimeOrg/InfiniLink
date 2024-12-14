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
            Section(footer: Text("Sync step and heart rate data to Apple Health.")) {
                Toggle("Apple Health", isOn: HealthKitManager.shared.$syncToAppleHealth)
            }
        }
        .navigationTitle("Data Sync")
    }
}

#Preview {
    DataSyncView()
}
