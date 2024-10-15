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
    
    @State private var authorizationStatus = MPMediaLibrary.authorizationStatus()
    
    var body: some View {
        Group {
            switch authorizationStatus {
            case .authorized:
                authorized
            case .denied, .notDetermined, .restricted:
                unauthorized
            @unknown default:
                unauthorized
            }
        }
        .onChange(of: allowMusicControl) { allowed in
            if allowed {
                MusicController.shared.initialize()
            }
        }
    }
    
    var unauthorized: some View {
        ActionView(action: Action(title: "We need access to your Music Library.", subtitle: "To control Apple Music from your watch, you'll need to give InfiniLink access to Apple Music.", icon: "music.note", action: {
            if authorizationStatus == .denied {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } else {
                MPMediaLibrary.requestAuthorization { status in
                    authorizationStatus = status
                }
            }
        }, actionLabel: authorizationStatus == .denied ? "Open Settings..." : "Allow Access...", accent: .blue))
    }
    
    var authorized: some View {
        List {
            Section(footer: Text("Allow your watch to control the currently playing music from Apple Music.")) {
                Toggle("Allow Music Control", isOn: $allowMusicControl)
            }
        }
        .navigationTitle("Music")
    }
}

#Preview {
    MusicSettingsView()
}
