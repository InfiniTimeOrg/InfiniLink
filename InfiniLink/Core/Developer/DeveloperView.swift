//
//  DeveloperView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct DeveloperView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("useExperimentalDFU") var useExperimentalDFU = false
    @AppStorage("includeTestArtist") var includeTestArtist = true
    @AppStorage("includeTestSongName") var includeTestSongName = true
    
    private let bleWriteManager = BLEWriteManager()
    private let musicController = MusicController.shared
    
    var body: some View {
        List {
            Section {
                NavigationLink("Debug Logs") {
                    DebugLogsView()
                }
            }
            Section("Test Data") {
                Button("Test Weather") {
                    bleWriteManager.writeForecastWeatherData(minimumTemperature: {
                        var mins = [Double]()
                        
                        for _ in 0...4 {
                            mins.append(Double.random(in: -2...50))
                        }
                        
                        return mins
                    }(), maximumTemperature: {
                        var maxs = [Double]()
                        
                        for _ in 0...4 {
                            maxs.append(Double.random(in: -2...50))
                        }
                        
                        return maxs
                    }(), icon: {
                        var icons = [UInt8]()
                        
                        for _ in 0...8 {
                            icons.append(UInt8.random(in: 0...8))
                        }
                        
                        return icons
                    }())
                    bleWriteManager.writeCurrentWeatherData(currentTemperature: Double.random(in: -2...50), minimumTemperature: Double.random(in: -2...50), maximumTemperature: Double.random(in: -2...50), location: "Location", icon: UInt8.random(in: 0...8))
                }
                Button("Test Navigation") {
                    bleWriteManager.writeNavigationUpdate()
                }
            }
            Section {
                Button("Test Music") {
                    if let playbackChar = bleManager.musicChars.position, let durationChar = bleManager.musicChars.length, let statusChar = bleManager.musicChars.status {
                        bleWriteManager.writeHexToMusicApp(message: musicController.convertTime(value: 78), characteristic: playbackChar)
                        bleWriteManager.writeHexToMusicApp(message: musicController.convertTime(value: 147), characteristic: durationChar)
                        
                        bleWriteManager.writeHexToMusicApp(message: Bool.random() ? [0x01] : [0x00], characteristic: statusChar)
                    }
                    
                    if let artistChar = bleManager.musicChars.artist, includeTestArtist {
                        bleWriteManager.writeToMusicApp(message: "Artist Name", characteristic: artistChar)
                    }
                    if let trackChar = bleManager.musicChars.track, includeTestSongName {
                        bleWriteManager.writeToMusicApp(message: "Song Name", characteristic: trackChar)
                    }
                }
            }
            Section {
                Toggle("Include Song Name", isOn: $includeTestSongName)
                Toggle("Include Artist", isOn: $includeTestArtist)
            } footer: {
                Text("Send randomly generated data to the various characteristics on the watch.")
            }
            Section {
                Toggle("Use Experimental DFU", isOn: $useExperimentalDFU)
            }
            Section("Charts") {
                Button(role: .destructive) {
                    StepCountManager.shared.clearCurrentDaySteps()
                } label: {
                    Text("Clear Step Data")
                }
            }
        }
        .navigationTitle("Developer")
    }
}

#Preview {
    DeveloperView()
}
