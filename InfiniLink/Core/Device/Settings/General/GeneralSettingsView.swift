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
            }
            Section {
                NavigationLink {
                    GoalsSettingsView()
                } label: {
                    Text("Daily Goals")
                }
            }
            Section {
                NavigationLink {
                    // Strava?
                    // Apple Health
                } label: {
                    Text("Data Sync")
                }
            }
            Section {
                Button {
                    bleManager.disconnect()
                } label: {
                    Text({
                        if bleManager.isScanning {
                            return "Scanning"
                        }
                        if bleManager.hasLoadedCharacteristics {
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
                .confirmationDialog("Are you sure you want to unpair from \(DeviceNameManager().getName(deviceUUID: bleManager.pairedDeviceID ?? "InfiniTime"))?", isPresented: $showUnpairConfirmation) {
                    Button(role: .destructive) {
                        bleManager.unpair()
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
