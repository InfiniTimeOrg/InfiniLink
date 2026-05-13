//
//  MusicSettingsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import MediaPlayer

struct MusicSettingsView: View {
    @AppStorage("allowMusicControl") var allowMusicControl = true
    @AppStorage("allowVolumeControl") var allowVolumeControl = true
    @AppStorage("pauseOnWalkaway") var pauseOnWalkaway = true
    
    @ObservedObject private var deviceManager = DeviceManager.shared
    
    @State private var authorizationStatus = MPMediaLibrary.authorizationStatus()
    
    var body: some View {
        Group {
            if authorizationStatus == .authorized {
                authorized
            } else {
                unauthorized
            }
        }
        .onAppear {
            MPMediaLibrary.requestAuthorization { self.authorizationStatus = $0 }
        }
    }
    
    var unauthorized: some View {
        ActionView(action: Action(title: "We need access to your Music Library.", subtitle: "To control Apple Music from your watch, you'll need to give InfiniLink access to Apple Music.", icon: "music.note", button: .init(action: { UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!) }, label: "Open Settings..."), accent: .blue))
    }
    
    var authorized: some View {
        List {
            Section(footer: Text("Allow your watch to control the currently playing music from Apple Music.")) {
                Toggle("Allow Music Control", isOn: $allowMusicControl)
            }
            Toggle("Allow Volume Control", isOn: $allowVolumeControl)
            Section(footer: Text("Pause any currently playing music when \(deviceManager.name) goes out of range of your phone.")) {
                Toggle("Pause on Walk-Away", isOn: $pauseOnWalkaway)
            }
        }
        .navigationTitle("Music")
    }
}

#Preview {
    MusicSettingsView()
}
