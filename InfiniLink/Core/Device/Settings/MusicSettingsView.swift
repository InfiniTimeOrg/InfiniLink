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
    
    let authorizationStatus = MPMediaLibrary.authorizationStatus()
    
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
        ZStack {
            Circle() // Remove?
                .frame(width: 150, height: 150)
                .foregroundStyle(.red)
                .blur(radius: 50)
            VStack(spacing: 18) {
                Image(systemName: "music.note")
                    .font(.system(size: 45))
                    .foregroundStyle(.primary.opacity(0.6))
                VStack(spacing: 10) {
                    Text("We need access to your Music Library.")
                        .font(.largeTitle.weight(.bold))
                    Text("To control Apple Music from your watch, you'll need to give InfiniLink access to Apple Music.")
                        .foregroundStyle(.gray)
                }
                Button {
                    MPMediaLibrary.requestAuthorization { _ in }
                } label: {
                    Text("Allow Access...")
                        .padding(12)
                        .padding(.horizontal, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .multilineTextAlignment(.center)
            .padding()
        }
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
