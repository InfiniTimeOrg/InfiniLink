//
//  GeneralSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @State private var showUnpairConfirmation = false
    @State private var showResetConfirmation = false
    
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    AboutSettingsView()
                } label: {
                    Text("About")
                }
                NavigationLink {
                    SoftwareUpdateView()
                } label: {
                    Text("Software Update")
                }
                NavigationLink {
                    FileSystemView()
                } label: {
                    Text("File System")
                }
                .disabled(bleManager.blefsTransfer == nil)
            }
            Section {
                NavigationLink {
                    AppearanceView()
                } label: {
                    Text("Appearance")
                }
                NavigationLink {
                    SetUpDetailsView(list: true)
                } label: {
                    Text("Health Details")
                }
                NavigationLink {
                    DataSyncView()
                } label: {
                    Text("Data Sync")
                }
            }
            Section {
                NavigationLink {
                    DeveloperModeSettingsView()
                } label: {
                    Text("Developer")
                }
            }
            Section {
                Button {
                    if bleManager.isConnectedToPinetime {
                        bleManager.disconnect()
                    } else {
                        bleManager.startScanning()
                    }
                } label: {
                    Text(bleManager.isConnectedToPinetime ? "Disconnect": "Connect")
                }
                .disabled(bleManager.isBusy)
            }
        }
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
}
