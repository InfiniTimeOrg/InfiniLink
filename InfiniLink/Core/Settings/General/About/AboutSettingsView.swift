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
    
    // Add state property because using deviceManager.name directly on the label won't update
    @State var name = ""
    
    @State var showAppInfoView = false
    
    var body: some View {
        Group {
            List {
                Section {
                    NavigationLink {
                        RenameView()
                    } label: {
                        AboutRowView(title: "Name", value: name)
                    }
                    AboutRowView(title: "Software Version", value: deviceManager.firmware)
                    AboutRowView(title: "Manufacturer", value: deviceManager.manufacturer)
                    AboutRowView(title: "Model Name", value: deviceManager.modelNumber)
                    AboutRowView(title: "UUID", value: deviceManager.bleUUID)
                }
                if let timeService = bleManager.currentTimeService{
                    Section {
                        Button("Update Device Time") {
                            BLEWriteManager().setTime(characteristic: timeService)
                        }
                    }
                }
                Section {
                    AboutRowView(title: "File System", value: deviceManager.blefsVersion)
                    AboutRowView(title: "Hardware Revision", value: deviceManager.hardwareRevision)
                    AboutRowView(title: "Settings Version", value: String(deviceManager.settings.version))
                }
                Section {
                    Button("About InfiniLink") {
                        showAppInfoView = true
                    }
                    .sheet(isPresented: $showAppInfoView) {
                        AppDetailsView()
                    }
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
