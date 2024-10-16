//
//  AboutSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    // Add state property because name won't update automatically
    @State var name = ""
    
    var body: some View {
        Group {
            List {
                Section {
                    NavigationLink {
                        RenameView()
                    } label: {
                        AboutRowView(title: "Name", value: name)
                    }
                    .disabled(!bleManager.hasLoadedCharacteristics)
                    AboutRowView(title: "Software Version", value: deviceManager.firmware)
                    AboutRowView(title: "Manufacturer", value: deviceManager.manufacturer)
                    AboutRowView(title: "Model Number", value: deviceManager.modelNumber)
                    AboutRowView(title: "UUID", value: deviceManager.bleUUID)
                }
                Section {
                    AboutRowView(title: "File System", value: deviceManager.blefsVersion)
                    AboutRowView(title: "Hardware Revision", value: deviceManager.hardwareRevision)
                    AboutRowView(title: "Settings Version", value: String(deviceManager.settings.version))
                }
            }
        }
        .navigationTitle("About")
        .onAppear {
            name = deviceManager.name
        }
    }
}

struct AboutRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(NSLocalizedString(title, comment: ""))
            Spacer()
            Text(value)
                .foregroundStyle(.gray)
        }
    }
}

#Preview {
    NavigationView {
        AboutSettingsView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
