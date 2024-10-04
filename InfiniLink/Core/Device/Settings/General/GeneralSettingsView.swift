//
//  GeneralSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    
                } label: {
                    Text("About")
                }
                NavigationLink {
                    SoftwareUpdateView()
                } label: {
                    Text("Software Update")
                }
            }
        }
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
}
