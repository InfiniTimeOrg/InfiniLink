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
                        RenameView($name)
                    } label: {
                        AboutRowView("Name", value: name)
                    }
                    AboutRowView("Software Version", value: deviceManager.firmware)
                    AboutRowView("Manufacturer", value: deviceManager.manufacturer)
                    AboutRowView("Model Name", value: deviceManager.modelNumber)
                    AboutRowView("UUID", value: deviceManager.bleUUID)
                }
                AboutRowView("ANCS Enabled", value: bleManager.infiniTime?.ancsAuthorized ?? false ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: ""))
                Section {
                    AboutRowView("File System", value: deviceManager.blefsVersion)
                    AboutRowView("Hardware Revision", value: deviceManager.hardwareRevision)
                    AboutRowView("Settings Version", value: String(deviceManager.settings.version))
                }
                Section {
                    Button("Update Device Time") {
                        BLEWriteManager().setTime(characteristic: bleManager.currentTimeService)
                    }
                    .disabled(bleManager.currentTimeService == nil)
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
    let canCopy: Bool
    
    init(_ title: LocalizedStringKey, value: String, allowCopy: Bool = true) {
        self.title = title
        self.value = value
        self.canCopy = allowCopy
    }
    
    var body: some View {
        let body = HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.gray)
        }
        
        if canCopy {
            body
                .contextMenu {
                    Button("Copy") {
                        UIPasteboard.general.string = value
                    }
                }
        } else {
            body
        }
    }
}

#Preview {
    NavigationView {
        AboutSettingsView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
