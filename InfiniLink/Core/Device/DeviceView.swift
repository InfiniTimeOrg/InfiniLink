//
//  DeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfoManager = DeviceInfoManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @AppStorage("sleepGoal") var sleepGoal = 28800
    
    @Environment(\.colorScheme) var colorScheme
    
    func connectionState() -> String {
        if bleManager.isScanning {
            return NSLocalizedString("Connecting...", comment: "")
        }
        switch (bleManager.isConnectedToPinetime, bleManager.hasLoadedBatteryLevel) {
        case (true, true):
            return NSLocalizedString("Connected", comment: "")
        case (true, false):
            return NSLocalizedString("Connecting...", comment: "")
        default:
            return NSLocalizedString("Disconnected", comment: "")
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                List {
                    VStack(spacing: 4) {
                        WatchFaceView(watchface: .constant(nil))
                            .frame(width: min(geo.size.width / 2.5, 185), height: min(geo.size.width / 2.5, 185), alignment: .center)
                            .clipped(antialiased: true)
                        VStack(spacing: 5) {
                            Group {
                                Text(connectionState()) + Text(bleManager.hasLoadedBatteryLevel ? " • " : "") + Text(bleManager.hasLoadedBatteryLevel ? "\(String(format: "%.0f", bleManager.batteryLevel))%" : "")
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
                            Text(DeviceInfoManager.shared.deviceName)
                                .font(.title.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    if downloadManager.updateAvailable  && !DFUUpdater.shared.local && bleManager.blefsTransfer != nil {
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
                                            .font(.body.weight(.bold))
                                        Group {
                                            Text("InfiniTime ") + Text(downloadManager.updateVersion).font(.body.weight(.medium))
                                        }
                                        .foregroundStyle(Color.gray)
                                    }
                                }
                            }
                        }
                    }
                    if !personalizationController.isPersonalizationAvailable {
                        Section {
                            Button {
                                personalizationController.showSetupSheet = true
                            } label: {
                                Text("Finish Setup")
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
                        /*
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Stress", icon: "face.smiling", iconColor: .black)
                        }
                         */
                    }
                    Section {
                        NavigationLink {
                            GeneralSettingsView()
                        } label: {
                            ListRowView(title: "General", icon: "gear", iconColor: .gray.opacity(0.9))
                        }
                        NavigationLink {
                            CustomizationView()
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
            .onChange(of: bleManager.blefsTransfer) { _ in
                if bleManager.blefsTransfer != nil {
                    BLEFSHandler.shared.readSettings { settings in
                        bleManager.setSettings(from: settings)
                    }
                }
            }
            .onAppear {
                DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: DeviceInfoManager.shared.firmware)
            }
        }
        .navigationViewStyle(.stack)
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
                .font(.system(size: 13).weight(.medium))
                .frame(width: 34, height: 34)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    DeviceView()
        .onAppear {
            DeviceInfoManager.shared.settings.watchFace = 4
            DeviceInfoManager.shared.firmware = "1.14.0"
            DownloadManager.shared.updateVersion = "1.14.1"
            DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
            DownloadManager.shared.updateAvailable = true
            DFUUpdater.shared.local = false
        }
}
