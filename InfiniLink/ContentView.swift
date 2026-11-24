//
//  ContentView.swift
//  InfiniLink
//
//  Created by Liam Emry on 10/2/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var downloadManager = DownloadManager.shared
    @ObservedObject private var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject private var importManager = ImportManager.shared
    @ObservedObject private var autoUpdateManager = AutoUpdateManager.shared

    @AppStorage("pairedDeviceID") private var pairedDeviceID: String?

    @State private var navigationID = UUID()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if pairedDeviceID != nil && horizontalSizeClass == .regular {
                NavigationSplitView {
                    DeviceView(isSidebar: true)
                } detail: {
                    NavigationStack {
                        GeneralSettingsView()
                    }
                }
            } else {
                NavigationStack {
                    if pairedDeviceID != nil {
                        DeviceView()
                    } else {
                        WelcomeView()
                    }
                }
                .id(navigationID)
            }
        }
        .alert(isPresented: $bleManager.showError) {
            Alert(title: Text("Error"), message: Text(bleManager.error), dismissButton: .default(Text("OK")))
        }
        // Recovery mode and external resources show the update inline on DeviceView
        .fullScreenCover(isPresented: Binding(
            get: { downloadManager.updateStarted && !bleManager.isDeviceInRecoveryMode && !downloadManager.externalResources },
            set: { downloadManager.updateStarted = $0 }
        )) {
            CurrentUpdateView()
        }
        .sheet(item: $exerciseViewModel.recoverableSession) { session in
            RecoverExerciseView(session: session)
        }
        .alert("Automatic Updates", isPresented: $autoUpdateManager.showOffer) {
            Button("Turn On") {
                autoUpdateManager.enabled = true
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Install future updates automatically while \(DeviceManager.shared.name) charges overnight? You can change this in Software Update settings.")
        }
        .onOpenURL { url in
            importManager.handleIncomingFile(url)
        }
        .alert("Couldn't Open File", isPresented: Binding(
            get: { importManager.importError != nil },
            set: { if !$0 { importManager.importError = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importManager.importError ?? "")
        }
        .sheet(isPresented: $importManager.showUpdateFlow) {
            NavigationStack {
                SoftwareUpdateView(isImport: true)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                importManager.showUpdateFlow = false
                            }
                        }
                    }
            }
        }
        .onChange(of: downloadManager.updateStarted) { started in
            if started && !downloadManager.externalResources { // Dismiss after the install starts
                importManager.showUpdateFlow = false
                if bleManager.isDeviceInRecoveryMode { // Pop to root to show the inline progress
                    navigationID = UUID()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
