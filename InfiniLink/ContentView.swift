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
    }
}

#Preview {
    ContentView()
}
