//
//  DeveloperView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI

struct DeveloperView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("includeTestArtist") var includeTestArtist = true
    @AppStorage("includeTestSongName") var includeTestSongName = true
    @AppStorage("forceAncs") var forceAncs = false
    
    @State private var heartDay = ""
    @State private var generatedDayOffset = 0
    
    private let bleWriteManager = BLEWriteManager()
    private let musicController = MusicController.shared
    private let healthKitManager = HealthKitManager.shared
    private let persistenceController = PersistenceController.shared

    func generateRandomHeartPoints(dayOffset: Int) {
        let context = persistenceController.container.viewContext
        
        let calendar = Calendar.current
        let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
        
        let startOfDay = calendar.startOfDay(for: targetDay)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        for _ in 0..<150 {
            let randomTime = TimeInterval.random(in: 0..<endOfDay.timeIntervalSince(startOfDay))
            let timestamp = startOfDay.addingTimeInterval(randomTime)
            
            let point = HeartDataPoint(context: context)
            point.deviceId = bleManager.pairedDeviceID
            point.timestamp = timestamp
            point.value = Double(Int.random(in: 55...165))
        }
        
        do {
            try context.save()
        } catch {
            log("Error generating heart points: \(error)", caller: "ChartManager")
        }
    }
    
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
                    bleWriteManager.writeNavigationUpdate(
                        icon: "turn-right",
                        instructions: "The destination is on your right",
                        distance: "112 ft",
                        progress: 98
                    )
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
                Toggle("Include Song Name", isOn: $includeTestSongName)
                Toggle("Include Artist", isOn: $includeTestArtist)
            } footer: {
                Text("Send randomly generated data to the various characteristics on the watch.")
            }
            Section("Test HealthKit") {
                Button("Save 300 Calories") {
                    healthKitManager.saveCalories(kcal: 300)
                }
                Button("Save 100 Steps") {
                    healthKitManager.writeSteps(100)
                }
            }
            Section("Test Steps") {
                Button("Add 2") {
                    let todaySteps = chartManager.stepPoints().first?.steps ?? 0
                    stepCountManager.setStepCount(Int(todaySteps + 2))
                }
                Button("Set to 0") {
                    stepCountManager.setStepCount(0)
                }
            }
            Toggle("Force ANCS", isOn: $forceAncs)
            Section("Test HRM") {
                TextField("Days", text: $heartDay)
                    .onSubmit {
                        generatedDayOffset = Int(heartDay) ?? 0
                    }
                Button("Add a Day") {
                    generateRandomHeartPoints(dayOffset: generatedDayOffset)
                }
            }
            Section {
                Button(role: .destructive) {
                    stepCountManager.clearCurrentDaySteps()
                } label: {
                    Text("Clear Step Data")
                }
                Button(role: .destructive) {
                    ChartManager.shared.clearHrmData()
                } label: {
                    Text("Clear HRM Data")
                }
                Button(role: .destructive) {
                    ChartManager.shared.deleteAllUserExercises()
                } label: {
                    Text("Clear All Exercises")
                }
            } header: {
                Text("DANGER ZONE")
            } footer: {
                Text("WARNING: These actions are permanent and cannot be undone!")
            }
        }
        .navigationTitle("Developer")
    }
}

#Preview {
    DeveloperView()
}
