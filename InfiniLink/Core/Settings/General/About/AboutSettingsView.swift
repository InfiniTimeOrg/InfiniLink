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
                        AboutRowView("Name", value: name)
                    }
                    AboutRowView("Software Version", value: deviceManager.firmware)
                    AboutRowView("Manufacturer", value: deviceManager.manufacturer)
                    AboutRowView("Model Name", value: deviceManager.modelNumber)
                    AboutRowView("UUID", value: deviceManager.bleUUID)
                }
                if let timeService = bleManager.currentTimeService{
                    Section {
                        Button("Update Device Time") {
                            BLEWriteManager().setTime(characteristic: timeService)
                        }
                    }
                }
                Section {
                    AboutRowView("File System", value: deviceManager.blefsVersion)
                    AboutRowView("Hardware Revision", value: deviceManager.hardwareRevision)
                    AboutRowView("Settings Version", value: String(deviceManager.settings.version))
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
    let title: LocalizedStringKey
    let value: String
    
    init(_ title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(title)
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
