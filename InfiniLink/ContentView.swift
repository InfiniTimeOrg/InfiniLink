//
//  ContentView.swift
//  InfiniLink
//
//  Created by Liam Emry on 10/2/24.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var downloadManager = DownloadManager.shared
    @ObservedObject private var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject private var importManager = ImportManager.shared

    @AppStorage("pairedDeviceID") private var pairedDeviceID: String?

    var body: some View {
        Group {
            if pairedDeviceID != nil {
                DeviceView()
            } else {
                WelcomeView()
            }
        }
        .alert(isPresented: $bleManager.showError) {
            Alert(title: Text("Error"), message: Text(bleManager.error), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $downloadManager.updateStarted) {
            CurrentUpdateView()
        }
        .sheet(item: $exerciseViewModel.recoverableSession) { session in
            RecoverExerciseView(session: session)
        }
        .onOpenURL { url in
            importManager.handleIncomingFile(url)
        }
        .alert(
            "Import Zip File",
            isPresented: Binding(
                get: { importManager.pendingZip != nil },
                set: { if !$0 { importManager.cancelImport() } }
            ),
            presenting: importManager.pendingZip
        ) { zip in
            Button("Firmware Update") {
                importManager.chooseFirmware(zip)
            }
            Button("External Resources") {
                importManager.chooseExternalResources(zip)
            }
            Button("Cancel", role: .cancel) {
                importManager.cancelImport()
            }
        } message: { zip in
            Text("What would you like to use \"\(zip.filename)\" for?")
        }
        .sheet(isPresented: $importManager.showUpdateFlow) {
            NavigationStack {
                SoftwareUpdateView()
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
            if started { // Dismiss after the install starts
                importManager.showUpdateFlow = false
            }
        }
    }
}

#Preview {
    ContentView()
}
