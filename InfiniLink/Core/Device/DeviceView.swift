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
    
    @Environment(\.colorScheme) var colorScheme
    
    func connectionState() -> String {
        bleManager.hasLoadedCharacteristics ? NSLocalizedString("Connected", comment: "") : (bleManager.isSwitchedOn ? NSLocalizedString("Connecting...", comment: "") : NSLocalizedString("Disconnected", comment: ""))
    }
    func deviceName() -> String {
        if let name = bleManager.infiniTime?.name, !name.isEmpty {
            return name
        } else {
            let name = DeviceNameManager().getName(deviceUUID: bleManager.pairedDeviceID ?? "")
            
            if name.isEmpty {
                return "InfiniTime"
            } else {
                return name
            }
        }
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
                            Text(deviceName())
                                .font(.title.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    // TODO: add complete setup section
                    if downloadManager.updateAvailable  && !DFUUpdater.shared.local {
                        Section {
                            NavigationLink {
                                SoftwareUpdateView()
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(.infiniTime)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Update Available")
                                                .font(.title2.weight(.bold))
                                            Group {
                                                Text("InfiniTime ") + Text(downloadManager.updateVersion)
                                                    .font(.body.weight(.semibold))
                                            }
                                            .foregroundStyle(Color.gray)
                                        }
                                    }
                                    Text(downloadManager.updateBody)
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 10)
                            }
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
                            
                        } label: {
                            ListRowView(title: "Stress", icon: "face.smiling")
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
                    }
                    Section {
                        NavigationLink {
                            GeneralSettingsView()
                        } label: {
                            ListRowView(title: "General", icon: "gear", iconColor: .gray)
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
                if firmware != "" {
                    if bleManager.blefsTransfer != nil {
                        BLEFSHandler.shared.readSettings { settings in
                            DispatchQueue.main.async {
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
                            }
                        }
                    }
                }
                DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: firmware)
            }
        }
    }
}

struct ListRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let iconColor: Color?
    
    init(title: String, icon: String, iconColor: Color? = nil) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
    }
    
    var body: some View {
        Label {
            Text(NSLocalizedString(title, comment: ""))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        } icon: {
            Image(systemName: icon)
            .foregroundStyle(iconColor ?? (colorScheme == .dark ? .white : .black))
        }
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
