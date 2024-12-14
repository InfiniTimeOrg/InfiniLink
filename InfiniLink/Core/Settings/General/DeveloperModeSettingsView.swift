//
//  DeveloperModeSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct DeveloperModeSettingsView: View {
    @AppStorage("enableDeveloperMode") var enableDeveloperMode = false
    
    var body: some View {
        List {
            Section(footer: Text("A new section will be added to your device overview.")) {
                Toggle("Enable Developer Mode", isOn: $enableDeveloperMode)
            }
        }
        .navigationTitle("Developer Mode")
    }
}

#Preview {
    DeveloperModeSettingsView()
}
