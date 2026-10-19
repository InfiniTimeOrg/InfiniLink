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
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    @AppStorage("enableDeveloperMode") var enableDeveloperMode = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showMyDevicesSheet = false
    @State private var showNavigationTitle = false

    // Used as the sidebar on iPad
    var isSidebar = false
    
    @ViewBuilder
    private func column<V: View>(_ view: V) -> some View {
        if isSidebar {
            NavigationStack {
                view
            }
        } else {
            view
        }
    }
    
    var body: some View {
        Group {
            if bleManager.isDeviceInRecoveryMode && bleManager.hasLoadedCharacteristics {
                RecoveryModeView()
            } else {
                content
            }
        }
    }
    
    var content: some View {
        GeometryReader { geo in
            List {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: [geo.frame(in: .global).minY])
                    }
                    .frame(height: 0)
                    VStack(spacing: 4) {
                        WatchFaceView(device: deviceManager.pairedDevice)
                            .frame(width: min(geo.size.width / 2.5, 185), height: min(geo.size.width / 2.5, 185), alignment: .center)
                            .clipped(antialiased: true)
                        VStack(spacing: 5) {
                            Text(deviceManager.name)
                                .font(.title.weight(.bold))
                            if bleManager.isBluetoothOn {
                                HStack(spacing: 0) {
                                    Text(bleManager.connectionState)
                                    if bleManager.hasLoadedBatteryLevel {
                                        Text(" • ")
                                        Text(bleManager.batteryLevel / 100, format: .percent.precision(.fractionLength(0)))
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
                                }
                                .foregroundStyle(Color.gray)
                            }
                        }
                        .opacity(showNavigationTitle ? 0 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                Section {
                    let comparison = deviceManager.firmware.compare(downloadManager.updateVersion, options: .numeric)
                    if !bleManager.isBluetoothOn {
                        // We don't use a button because there's no App Store-safe way to deeplink to Settings without opening InfiniLink settings, which could confuse the user
                        BannerView("Bluetooth Disabled", "To connect to your watch, you'll need to enable Bluetooth.") {
                            Image("logo.bluetooth")
                                .resizable()
                                .frame(width: 21, height: 35)
                                .foregroundStyle(.blue)
                        }
                    } else if let exercise = exerciseViewModel.currentExercise {
                        NavigationLink {
                            column(ActiveExerciseView())
                        } label: {
                            BannerView("\(exercise.name)", "\(exerciseViewModel.timeString())", "Active Exercise") {
                                Image(systemName: exercise.icon)
                                    .font(.title2.weight(.medium))
                            }
                        }
                    } else if downloadManager.updateAvailable && !DFUUpdater.shared.local && bleManager.dfuControlPointCharacteristic != nil && comparison != .orderedDescending && comparison != .orderedSame {
                        NavigationLink {
                            column(SoftwareUpdateView())
                        } label: {
                            BannerView(
                                "InfiniTime",
                                "\(downloadManager.updateVersion)",
                                "Update Available"
                            ) {
                                Image(.infiniTime)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                            }
                        }
                    } else if let update = downloadManager.appUpdate {
                        Button {
                            guard let testFlight = URL(string: testFlightLink) else { return }
                            guard let appStore = URL(string: appStoreLink) else { return }
                            
                            openURL(update.isBeta ? testFlight : appStore)
                        } label: {
                            BannerView(
                                "InfiniLink",
                                "\(update.version)",
                                "Update Available"
                            ) {
                                Image((UIApplication.shared.alternateIconName ?? "AppIcon") + "-Rendered")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                Section {
                    NavigationLink {
                        column(ExerciseView())
                    } label: {
                        ListRowView(title: "Exercise", icon: "figure.run", iconColor: .orange)
                    }
                    NavigationLink {
                        column(HeartView())
                    } label: {
                        ListRowView(title: "Heart", icon: "heart.fill", iconColor: .red)
                    }
                    NavigationLink {
                        column(StepsView())
                    } label: {
                        ListRowView(title: "Steps", icon: "shoeprints.fill", iconColor: .blue)
                    }
                    if SleepManager.shared.isSupported {
                        NavigationLink {
                            column(SleepView())
                        } label: {
                            ListRowView(title: "Sleep", icon: "bed.double.fill", iconColor: .indigo)
                        }
                    }
                }
                Section {
                    NavigationLink {
                        column(GeneralSettingsView())
                    } label: {
                        ListRowView(title: "General", icon: "gear", iconColor: .gray.opacity(0.9))
                    }
                    NavigationLink {
                        column(WatchSettingsView())
                    } label: {
                        ListRowView(title: "Customization", icon: "wrench.fill", iconColor: .gray)
                    }
                    NavigationLink {
                        column(BatterySettingsView())
                    } label: {
                        ListRowView(title: "Battery", icon: "battery.100percent", iconColor: .green)
                    }
                    NavigationLink {
                        column(NotificationsSettingsView())
                    } label: {
                        ListRowView(title: "Notifications", icon: "bell.badge.fill", iconColor: .red)
                    }
                    if WatchAlarmFile.supported(onFirmware: deviceManager.firmware) {
                        NavigationLink {
                            column(WatchAlarmView())
                        } label: {
                            ListRowView(title: "Alarm", icon: "alarm.fill", iconColor: .orange)
                        }
                    }
                    NavigationLink {
                        column(WeatherView())
                    } label: {
                        ListRowView(title: "Weather", icon: "sun.max.fill", iconColor: .yellow)
                    }
                    NavigationLink {
                        column(DirectionsView())
                    } label: {
                        ListRowView(title: "Navigation", icon: "map.fill", iconColor: .blue, isBeta: true)
                    }
                    NavigationLink {
                        column(MusicSettingsView())
                    } label: {
                        ListRowView(title: "Music", icon: "music.note", iconColor: .red)
                    }
                }
                if enableDeveloperMode {
                    NavigationLink {
                        column(DeveloperView())
                    } label: {
                        ListRowView(title: "Developer", icon: "hammer.fill", iconColor: .gray)
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
                        .fontWeight(.regular)
                }
            }
        }
        .onChange(of: bleManager.blefsTransfer) { blefsTransfer in
            if blefsTransfer != nil && scenePhase == .active {
                BLEFSHandler.shared.readSettings { settings in
                    guard let settings else { return }
                    
                    DispatchQueue.main.async {
                        self.deviceManager.updateSettings(settings)
                    }
                }
            }
        }
        .onChange(of: bleManager.weatherCharacteristic) { _ in
            WeatherController.shared.fetchWeatherData()
        }
        .sheet(isPresented: $personalizationController.showSetupSheet) {
            SetUpDetailsView()
        }
        .sheet(isPresented: $showMyDevicesSheet) {
            MyDevicesView()
        }
    }
}

struct ListRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let iconColor: Color
    let isBeta: Bool
    
    init(title: String, icon: String, iconColor: Color? = nil, isBeta: Bool = false) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor ?? .blue
        self.isBeta = isBeta
    }
    
    var body: some View {
        Label {
            HStack(spacing: 6) {
                Text(NSLocalizedString(title, comment: ""))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                if isBeta {
                    Text("Beta")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(.blue)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 14).weight(.medium))
                .frame(width: 31, height: 31)
                .background(colorScheme == .dark ? AnyShapeStyle(Gradient(colors: [Color(.darkGray), Color.black.opacity(0.6)])) : AnyShapeStyle(iconColor))
                .clipShape(.rect(cornerRadius: 8))
                .foregroundStyle(colorScheme == .dark ? iconColor : .white)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 0.3)
                }
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
            DeviceManager.shared.pairedDevice?.firmware = "0.14.1"
            DownloadManager.shared.updateBody = "Testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing testing."
            DFUUpdater.shared.local = false
        }
}
