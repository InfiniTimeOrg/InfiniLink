//
//  GeneralSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @State private var showUnpairConfirmation = false
    
    @ObservedObject var bleManager = BLEManager.shared
    
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
                    SetUpDetailsView(listOnly: true)
                } label: {
                    Text("Health Details")
                }
                NavigationLink {
                    GoalsSettingsView()
                } label: {
                    Text("Daily Goals")
                }
            }
            Section {
                NavigationLink {
                    DataSyncView()
                } label: {
                    Text("Data Sync")
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
                    Text({
                        if bleManager.isScanning {
                            return "Scanning..."
                        }
                        if bleManager.isConnectedToPinetime {
                            return "Disconnect"
                        } else {
                            return "Connect"
                        }
                    }())
                }
                .disabled(bleManager.isScanning)
                Button(role: .destructive) {
                    showUnpairConfirmation = true
                } label: {
                    Text("Unpair")
                }
                .confirmationDialog("Are you sure you want to unpair from \("InfiniTime")?", isPresented: $showUnpairConfirmation) {
                    Button(role: .destructive) {
                        bleManager.unpair()
                        dismiss()
                    } label: {
                        Text("Unpair")
                    }
                }
            }
        }
        .navigationTitle("General")
    }
}

#Preview {
    GeneralSettingsView()
}
