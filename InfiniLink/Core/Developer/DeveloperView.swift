//
//  DeveloperView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/14/24.
//

import SwiftUI
import Combine

struct DeveloperView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var mockWatch = MockWatch.shared
    
    @AppStorage("includeTestArtist") var includeTestArtist = true
    @AppStorage("includeTestSongName") var includeTestSongName = true
    @AppStorage("forceAncs") var forceAncs = true
    @AppStorage("enableBetaNavigation") var enableBetaNavigation = false
    @AppStorage("dfuPacketReceiptNotification") var packetReceiptNotification = 0
    
    @State private var heartDay = ""
    @State private var generatedDayOffset = 0
    
    private let bleWriteManager = BLEWriteManager()
    private let musicController = MusicController.shared
    private let healthKitManager = HealthKitManager.shared
    private let deviceManager = DeviceManager.shared
    private let chartManager = ChartManager.shared
    private let stepCountManager = StepCountManager.shared
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
            point.deviceId = deviceManager.pairedDeviceID
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
                NavigationLink("Connection Diagnostics") {
                    ConnectionDiagnosticsView()
                }
            }
            if MockWatch.isAvailable && deviceManager.pairedDeviceID == MockWatch.id {
                Section("Simulated Watch") {
                    Toggle("Connected", isOn: Binding(get: { mockWatch.isConnected }, set: { $0 ? mockWatch.connect() : bleManager.disconnect() }))
                    Stepper("Battery: \(mockWatch.batteryLevel)%", value: Binding(get: { mockWatch.batteryLevel }, set: { mockWatch.setBatteryLevel($0) }), in: 0...100, step: 5)
                }
            }
            Toggle("Force ANCS", isOn: $forceAncs)
            Toggle("Fake Recovery Mode", isOn: $bleManager.fakeRecoveryMode)
            Section {
                Toggle("Enable Navigation (beta)", isOn: $enableBetaNavigation)
            }
            Section {
                Picker("Packet Receipt Notification", selection: $packetReceiptNotification) {
                    ForEach([0, 10, 12, 16, 18, 20, 24], id: \.self) { value in
                        Text(value == 0 ? "Disabled" : "\(value)").tag(value)
                    }
                }
            } header: {
                Text("Software Update")
            } footer: {
                Text("Firmware packets sent between the watch's flow-control acks. Low values result in slower updates, and high values result in faster updates, but send big bursts that can drop the update.")
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
                    let daytime = Bool.random()
                    let sunrise = Date().addingTimeInterval(daytime ? -Double.random(in: 3600...14400) : Double.random(in: 1800...5400))
                    let sunset = Date().addingTimeInterval(daytime ? Double.random(in: 3600...14400) : Double.random(in: 7200...14400))
                    bleWriteManager.writeCurrentWeatherData(currentTemperature: Double.random(in: -2...50), minimumTemperature: Double.random(in: -2...50), maximumTemperature: Double.random(in: -2...50), location: "Location", icon: UInt8.random(in: 0...8), sunrise: sunrise, sunset: sunset)
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
            Button("Dump Motion Activity") {
                let points = chartManager.motionActivityPoints(predicate: chartManager.sevenDayPredicate)
                log("\(points.count) motion activity points in the last 7 days", type: .info, caller: "DeveloperView")
                
                for point in points.suffix(50) {
                    log("\(point.timestamp?.formatted() ?? "?"): \(point.value)", type: .info, caller: "DeveloperView")
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
                    chartManager.clearHrmData()
                } label: {
                    Text("Clear HRM Data")
                }
                Button(role: .destructive) {
                    chartManager.deleteAllUserExercises()
                } label: {
                    Text("Clear All Exercises")
                }
                Button(role: .destructive) {
                    bleManager.disconnect()
                    deviceManager.pairedDeviceID = nil
                    deviceManager.deleteAllDevices()
                } label: {
                    Text("Delete All Devices")
                }
                Button(role: .destructive) {
                    chartManager.deleteAllDisconnectMapPoints()
                } label: {
                    Text("Clear Disconnect Pins")
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

struct ConnectionDiagnosticsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var rssiTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        List {
            Section {
                AboutRowView("Status", value: bleManager.connectionState)
                if bleManager.isConnectedToPinetime, let rssi = bleManager.rssi {
                    HStack {
                        Text("Signal")
                        Spacer()
                        Text("\(rssi) dBm")
                            .foregroundStyle(.gray)
                        Text(RSSI.from(rssi: rssi).connectionStrength)
                            .foregroundStyle(RSSI.from(rssi: rssi).color)
                    }
                }
                AboutRowView("ANCS", value: bleManager.ancsAuthorized ? NSLocalizedString("Authorized", comment: "") : NSLocalizedString("Not Authorized", comment: ""))
            }
            Section {
                AboutRowView("Disconnects This Session", value: "\(bleManager.disconnectCount)")
                if let date = bleManager.lastDisconnectDate {
                    HStack {
                        Text("Last Disconnect")
                        Spacer()
                        Text(date, format: .relative(presentation: .named))
                            .foregroundStyle(.gray)
                    }
                    AboutRowView("Reason", value: bleManager.lastDisconnectReason ?? NSLocalizedString("Disconnected by InfiniLink", comment: ""))
                }
                if let date = bleManager.lastDataReceivedDate {
                    HStack {
                        Text("Last Data Received")
                        Spacer()
                        Text(date, format: .relative(presentation: .named))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .navigationTitle("Connection Diagnostics")
        .onAppear {
            bleManager.infiniTime?.readRSSI()
        }
        .onReceive(rssiTimer) { _ in
            // Reading the RSSI also re-renders the relative dates above
            bleManager.infiniTime?.readRSSI()
        }
    }
}

#Preview {
    DeveloperView()
}
