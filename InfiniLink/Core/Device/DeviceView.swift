//
//  DeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @AppStorage("sleepGoal") var sleepGoal = 28800
    
    @AppStorage("weight") var weight: Int?
    @AppStorage("age") var age: Int?
    @AppStorage("height") var height: Int?
    
    @AppStorage("deviceName") var deviceName = ""
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    @Environment(\.colorScheme) var colorScheme
    
    func connectionState() -> String {
        bleManager.hasLoadedCharacteristics ? NSLocalizedString("Connected", comment: "") : (bleManager.isSwitchedOn ? NSLocalizedString("Connecting...", comment: "") : NSLocalizedString("Disconnected", comment: ""))
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                List {
                    VStack(spacing: 4) {
                        ZStack {
                            WatchFaceView(watchface: $bleManager.watchFace)
                                .frame(width: geo.size.width / 2.5, height: geo.size.width / 2.5, alignment: .center)
                                .clipped(antialiased: true)
                        }
                        VStack(spacing: 5) {
                            Group {
                                Text(connectionState()) + Text(bleManager.hasLoadedCharacteristics ? " • " : "") + Text(bleManager.hasLoadedCharacteristics ? "\(String(format: "%.0f", bleManager.batteryLevel))%" : "")
                                    .foregroundColor({
                                        if bleManager.batteryLevel > 20 {
                                            return Color.gray
                                        } else if bleManager.batteryLevel > 10 {
                                            return Color.orange
                                        } else {
                                            return Color.red
                                        }
                                    }())
                            }
                            .foregroundStyle(Color.gray)
                            Text(deviceName)
                                .font(.title.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    // TODO: add complete setup section if user skips onboarding setup
                    if downloadManager.updateAvailable  && !DFUUpdater.shared.local {
                        Section {
                            NavigationLink {
                                SoftwareUpdateView()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(.infiniTime)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Update Available")
                                            .font(.title2.weight(.bold))
                                        Group {
                                            Text("InfiniTime ") + Text(downloadManager.updateVersion)
                                                .font(.body.weight(.semibold))
                                        }
                                        .foregroundStyle(Color.gray)
                                    }
                                }
                            }
                        }
                    }
                    // User has dismissed the sheet, but didn't add one of the properties
                    if !showSetupSheet && (weight == nil || height == nil || age == nil) {
                        Section {
                            Button {
                                showSetupSheet = true
                            } label: {
                                Text("Complete Setup")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .overlay {
                            Text("1")
                                .padding(10)
                                .foregroundStyle(.white)
                                .background(Color.red)
                                .clipShape(Circle())
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    Section {
                        NavigationLink {
                            ExerciseView()
                        } label: {
                            ListRowView(title: "Exercise", icon: "figure.run", iconColor: .orange)
                        }
                        NavigationLink {
                            HeartView()
                        } label: {
                            ListRowView(title: "Heart Rate", icon: "heart.fill", iconColor: .red)
                        }
                        NavigationLink {
                            StepsView()
                        } label: {
                            ListRowView(title: "Steps", icon: "shoeprints.fill", iconColor: .blue)
                        }
                        NavigationLink {
                            SleepView()
                        } label: {
                            ListRowView(title: "Sleep", icon: "bed.double.fill", iconColor: Color(.systemPurple))
                        }
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Stress", icon: "face.smiling", iconColor: .black)
                        }
                    }
                    Section {
                        NavigationLink {
                            GeneralSettingsView()
                        } label: {
                            ListRowView(title: "General", icon: "gear", iconColor: .gray.opacity(0.9))
                        }
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Customization", icon: "paintbrush.fill", iconColor: .blue)
                        }
                        NavigationLink {
                            BatterySettingsView()
                        } label: {
                            ListRowView(title: "Battery", icon: "battery.100percent", iconColor: .green)
                        }
                        NavigationLink {
                            NotificationsSettingsView()
                        } label: {
                            ListRowView(title: "Notifications", icon: "bell.badge.fill", iconColor: .red)
                        }
                        NavigationLink {
                            WeatherSettingsView()
                        } label: {
                            ListRowView(title: "Weather", icon: "sun.max.fill", iconColor: .yellow)
                        }
                        NavigationLink {
                            MusicSettingsView()
                        } label: {
                            ListRowView(title: "Music", icon: "music.note", iconColor: .red)
                        }
                    }
                    Section {
                        NavigationLink {
                            AlarmView()
                        } label: {
                            ListRowView(title: "Alarms", icon: "alarm.fill")
                        }
                        NavigationLink {
                            RemindersView()
                        } label: {
                            ListRowView(title: "Reminders", icon: "checklist")
                        }
                    }
                }
            }
            .onChange(of: DeviceInfoManager.shared.firmware) { firmware in
                if !firmware.isEmpty {
                    if bleManager.blefsTransfer != nil {
                        BLEFSHandler.shared.readSettings { settings in
//                            DispatchQueue.main.async {
                                self.stepCountGoal = Int(settings.stepsGoal)
                                self.bleManager.watchFace = Int(settings.watchFace)
                                self.bleManager.pineTimeStyleData = settings.pineTimeStyle
                                self.bleManager.timeFormat = settings.clockType
                                self.bleManager.infineatWatchFace = settings.watchFaceInfineat
                                switch settings.weatherFormat {
                                case .Metric:
                                    self.bleManager.weatherMode = "metric"
                                case .Imperial:
                                    self.bleManager.weatherMode = "imperial"
                                }
//                            }
                        }
                    }
                }
            }
            .onAppear {
                DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: DeviceInfoManager.shared.firmware)
            }
        }
    }
}

struct ListRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let iconColor: Color
    
    init(title: String, icon: String, iconColor: Color? = nil) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor ?? .blue
    }
    
    var body: some View {
        Label {
            Text(NSLocalizedString(title, comment: ""))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 14).weight(.medium))
                .frame(width: 36, height: 36)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 0.1)
    }
}

struct TrendRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let icon: String
    let accent: Color
    let value: Int
    let maxValue: Int
    
    var progress: Double {
        return Double(value) / Double(maxValue)
    }
    
    var body: some View {
        Circle()
            .stroke(colorScheme == .dark ? Color(.darkGray).opacity(0.7) : Color.white, lineWidth: 4)
            .frame(width: 85, height: 85)
            .overlay {
                VStack(spacing: 2.5) {
                    Image(systemName: icon)
                        .imageScale(.large)
                    Text(String(value))
                }
                .foregroundStyle(accent)
            }
            .overlay {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 85, height: 85)
            }
    }
}

#Preview {
    DeviceView()
        .onAppear {
            BLEManager.shared.watchFace = 4
            DeviceInfoManager.shared.firmware = "1.14.0"
            DownloadManager.shared.updateVersion = "1.14.1"
            DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
            DownloadManager.shared.updateAvailable = true
            DFUUpdater.shared.local = false
        }
}
