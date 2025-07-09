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
                    ListRowView(title: "About", icon: "watch.analog", iconColor: .gray)
                }
                NavigationLink {
                    SoftwareUpdateView()
                } label: {
                    ListRowView(title: "Software Update", icon: "gear.badge", iconColor: .gray)
                }
                NavigationLink {
                    FileSystemView()
                } label: {
                    ListRowView(title: "File System", icon: "doc.on.doc.fill", iconColor: .gray)
                }
                .disabled(bleManager.blefsTransfer == nil)
            }
            Section {
                NavigationLink {
                    AppearanceView()
                } label: {
                    ListRowView(title: "Appearance", icon: "sun.max.fill")
                }
                NavigationLink {
                    SetUpDetailsView(list: true)
                } label: {
                    ListRowView(title: "Health Details", icon: "figure.walk", iconColor: .gray)
                }
                NavigationLink {
                    DataSyncView()
                } label: {
                    ListRowView(title: "Data Sync", icon: "arrow.triangle.2.circlepath", iconColor: .green)
                }
            }
            Section {
                NavigationLink {
                    DeveloperModeSettingsView()
                } label: {
                    ListRowView(title: "Developer", icon: "hammer.fill", iconColor: .gray)
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
