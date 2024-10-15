//
//  AboutSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject var deviceInfoManager = DeviceInfoManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        Group {
            List {
                Section {
                    NavigationLink {
                        RenameView()
                    } label: {
                        AboutRowView(title: "Name", value: deviceInfoManager.deviceName)
                    }
                    .disabled(!bleManager.hasLoadedCharacteristics)
                    AboutRowView(title: "Software Version", value: deviceInfoManager.firmware)
                    AboutRowView(title: "Manufacturer", value: deviceInfoManager.manufacturer)
                    AboutRowView(title: "Model Number", value: deviceInfoManager.modelNumber)
                }
                Section {
                    AboutRowView(title: "Last Connect", value: Date(timeIntervalSince1970: deviceInfoManager.lastConnect).formatted())
                    AboutRowView(title: "Last Disconnect", value: Date(timeIntervalSince1970: deviceInfoManager.lastDisconnect).formatted())
                }
                Section {
                    AboutRowView(title: "File System", value: deviceInfoManager.blefsVersion)
                    AboutRowView(title: "Hardware Revision", value: deviceInfoManager.hardwareRevision)
                    AboutRowView(title: "Settings Version", value: String(deviceInfoManager.settingsVersion))
                }
            }
        }
        .navigationTitle("About")
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
            .onAppear {
                DeviceInfoManager.shared.firmware = "1.14.1"
                DeviceInfoManager.shared.deviceName = "InfiniTime"
                DeviceInfoManager.shared.manufacturer = "PineTime"
                DeviceInfoManager.shared.modelNumber = "1H7GJ8033"
                DeviceInfoManager.shared.serial = "1AG48J6QQ3"
                DeviceInfoManager.shared.blefsVersion = "1.2"
                DeviceInfoManager.shared.hardwareRevision = "2.0"
                DeviceInfoManager.shared.softwareRevision = "InfiniTime"
            }
    }
}
