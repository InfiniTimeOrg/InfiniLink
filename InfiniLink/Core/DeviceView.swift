//
//  DeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI

struct DeviceView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var personalizationController = PersonalizationController.shared
    @ObservedObject var remindersManager = RemindersManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    @AppStorage("sleepGoal") var sleepGoal = 28800
    @AppStorage("enableDeveloperMode") var enableDeveloperMode = false
    @AppStorage("enableReminders") var enableReminders = true
    @AppStorage("enableCalendarNotifications") var enableCalendarNotifications = true
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showMyDevicesSheet = false
    @State private var showNavigationTitle = false
    
    func connectionState() -> String {
        if bleManager.isBusy {
            return NSLocalizedString("Connecting...", comment: "")
        }
        switch (bleManager.isConnectedToPinetime, bleManager.hasLoadedBatteryLevel) {
        case (true, true):
            return NSLocalizedString("Connected", comment: "")
        case (true, false):
            return NSLocalizedString("Connecting...", comment: "")
        default:
            if bleManager.hasDisconnectedForUpdate {
                return NSLocalizedString("Installing update...", comment: "")
            } else {
                return NSLocalizedString("Disconnected", comment: "")
            }
        }
    }
    
    var body: some View {
        Group {
            if downloadManager.updateStarted {
                CurrentUpdateView()
            } else {
                if bleManager.isDeviceInRecoveryMode {
                    RecoveryModeView()
                } else {
                    content
                }
            }
        }
    }
    
    var content: some View {
        NavigationView {
            GeometryReader { geo in
                List {
                    VStack(spacing: 0) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                        }
                        .frame(height: 0)
                        VStack(spacing: 4) {
                            WatchFaceView(watchface: nil, device: bleManager.pairedDevice)
                                .frame(width: min(geo.size.width / 2.5, 185), height: min(geo.size.width / 2.5, 185), alignment: .center)
                                .clipped(antialiased: true)
                            VStack(spacing: 5) {
                                Text(deviceManager.name)
                                    .font(.title.weight(.bold))
                                if bleManager.isBluetoothOn {
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
                                }
                            }
                            .opacity(showNavigationTitle ? 0 : 1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    let comparison = deviceManager.firmware.compare(downloadManager.updateVersion, options: .numeric)
                    if !bleManager.isBluetoothOn {
                        // We don't use a button because there's no App Store-safe way to deeplink to Settings without opening InfiniLink settings, which could confuse the user
                        Section {
                            HStack(spacing: 14) {
                                // Make sure we show the current app icon
                                Image("logo.bluetooth")
                                    .resizable()
                                    .frame(width: 21, height: 35)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Bluetooth Disabled")
                                        .foregroundStyle(Color.primary)
                                        .fontWeight(.bold)
                                    Text("To connect to your watch, you'll need to enable Bluetooth.")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    } else if let exercise = exerciseViewModel.currentExercise {
                        Section {
                            NavigationLink {
                                ActiveExerciseView()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: exercise.icon)
                                        .font(.title2.weight(.medium))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Active Exercise")
                                            .font(.system(size: 13).weight(.medium))
                                            .foregroundStyle(.gray)
                                        Text(exercise.name)
                                            .foregroundStyle(Color.primary)
                                            .fontWeight(.bold)
                                        Text(exerciseViewModel.timeString())
                                    }
                                }
                            }
                        }
                    } else if downloadManager.updateAvailable && !DFUUpdater.shared.local && bleManager.dfuControlPointCharacteristic != nil && comparison != .orderedDescending && comparison != .orderedSame {
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
                                            .foregroundStyle(Color.primary)
                                            .fontWeight(.bold)
                                        Group {
                                            Text("InfiniTime ") + Text(downloadManager.updateVersion).font(.body.weight(.medium))
                                        }
                                        .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                    } else if let update = downloadManager.appUpdate {
                        Section {
                            Button {
                                guard let testFlight = URL(string: testFlightLink) else { return }
                                guard let appStore = URL(string: appStoreLink) else { return }
                                
                                openURL(update.isBeta ? testFlight : appStore)
                            } label: {
                                HStack(spacing: 10) {
                                    // Make sure we show the current app icon
                                    Image((UIApplication.shared.alternateIconName ?? "AppIcon") + "-Rendered")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("App Update Available")
                                            .foregroundStyle(Color.primary)
                                            .fontWeight(.bold)
                                        Group {
                                            Text("InfiniLink ") +
                                            Text(update.version)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundStyle(.gray)
                                    }
                                }
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
                            ListRowView(title: "Heart", icon: "heart.fill", iconColor: .red)
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
                            ListRowView(title: "General", icon: "gear", iconColor: .gray.opacity(0.9))
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
                            DirectionsView()
                        } label: {
                            ListRowView(title: "Navigation", icon: "map.fill", iconColor: .blue)
                        }
                        NavigationLink {
                            WeatherView()
                        } label: {
                            ListRowView(title: "Weather", icon: "sun.max.fill", iconColor: .yellow)
                        }
                        NavigationLink {
                            MusicSettingsView()
                        } label: {
                            ListRowView(title: "Music", icon: "music.note", iconColor: .red)
                        }
                    }
                    if enableDeveloperMode {
                        Section {
                            NavigationLink {
                                DeveloperView()
                            } label: {
                                ListRowView(title: "Developer", icon: "hammer.fill", iconColor: .gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle(showNavigationTitle ? deviceManager.name : "")
            .navigationBarTitleDisplayMode(.inline)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { values in
                guard let value = values.first else { return }
                
                self.showNavigationTitle = (value <= -135)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMyDevicesSheet = true
                    } label: {
                        Text("My Watches")
                    }
                }
            }
            .onChange(of: bleManager.blefsTransfer) { blefsTransfer in
                if blefsTransfer != nil && scenePhase == .active {
                    BLEFSHandler.shared.readSettings { settings in
                        deviceManager.updateSettings(settings: settings)
                    }
                }
            }
            .onAppear {
                bleManager.pairedDevice = deviceManager.fetchDevice()
                
                notificationManager.setWaterRemindersPerDay()
                
                if !personalizationController.showSetupSheet {
                    // We've already gone through the inital setup and the user has enabled reminder/calendar notifications so set state and fetch the events
                    if enableReminders {
                        remindersManager.requestReminderAccess()
                    }
                    if enableCalendarNotifications {
                        remindersManager.requestCalendarAccess()
                    }
                }
            }
            .onChange(of: bleManager.weatherCharacteristic) { _ in
                WeatherController.shared.fetchWeatherData()
            }
            .onChange(of: bleManager.batteryLevel) { bat in
                notificationManager.checkToSendLowBatteryNotification()
            }
            .sheet(isPresented: $personalizationController.showSetupSheet) {
                SetUpDetailsView()
            }
            .sheet(isPresented: $showMyDevicesSheet) {
                MyDevicesView()
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = [CGFloat]()
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        if let newValue = nextValue().first {
            value = [newValue]
        }
    }
}

#Preview {
    DeviceView()
        .onAppear {
            BLEManager.shared.pairedDevice?.firmware = "0.14.1"
            DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
            DFUUpdater.shared.local = false
        }
}
