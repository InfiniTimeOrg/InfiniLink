//
//  StepSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/11/25.
//

import SwiftUI

struct StepSettingsView: View {
    @AppStorage("addInsteadOfOverwrite") var addInsteadOfOverwrite: Bool = false
    
    var body: some View {
        List {
            Section {
                Toggle("Track Resets", isOn: $addInsteadOfOverwrite)
            } footer: {
                Text("If the watch reboots, add steps to the saved count instead of resetting it to zero.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    StepSettingsView()
}
