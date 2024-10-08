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
        ZStack {
            Circle()
                .frame(width: 150, height: 150)
                .foregroundStyle(.blue)
                .blur(radius: 50)
            VStack(spacing: 20) {
                Image(systemName: "music.note")
                    .font(.system(size: 55).weight(.bold))
                    .foregroundStyle(.primary.opacity(0.6))
                VStack(spacing: 12) {
                    Text("We need access to your Music Library.")
                        .font(.largeTitle.weight(.bold))
                    Text("To control Apple Music from your watch, you'll need to give InfiniLink access to Apple Music.")
                        .foregroundStyle(.gray)
                }
                Button {
                    if authorizationStatus == .denied {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    } else {
                        MPMediaLibrary.requestAuthorization { status in
                            authorizationStatus = status
                        }
                    }
                } label: {
                    Text(authorizationStatus == .denied ? "Open Settings..." : "Allow Access...")
                        .padding(12)
                        .padding(.horizontal, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxHeight: .infinity)
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
