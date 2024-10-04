//
//  DeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
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
                        VStack {
                            Text(deviceName())
                                .font(.title.weight(.bold))
                            Text(connectionState() + (bleManager.hasLoadedCharacteristics ? " • \(String(format: "%.0f", bleManager.batteryLevel))%" : ""))
                                .foregroundStyle({
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
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    Section {
                        HStack {
                            TrendRowView(icon: "figure.walk", accent: .blue, value: bleManager.stepCount, maxValue: stepCountGoal)
                            Spacer()
                            // TODO: do something a little different for heart rate
                            TrendRowView(icon: "heart.fill", accent: .red, value: Int(bleManager.heartRate), maxValue: 1)
                            Spacer()
                            TrendRowView(icon: "bed.double.fill",
                                         accent: .purple,
                                         value: bleManager.stepCount, // TODO: replace with real value
                                         maxValue: sleepGoal)
                        }
                    }
                    .listRowBackground(Color.clear)
                    Section {
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Exercise", icon: "figure.run", iconColor: Color(.systemOrange))
                        }
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Heart", icon: "heart.fill", iconColor: .red)
                        }
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Steps", icon: "shoeprints.fill", iconColor: .blue)
                        }
                        NavigationLink {
                            
                        } label: {
                            ListRowView(title: "Sleep", icon: "bed.double.fill", iconColor: .purple)
                        }
                    }
                    Section {
                        NavigationLink {
                            GeneralSettingsView()
                        } label: {
                            ListRowView(title: "General", icon: "gear")
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
                            ListRowView(title: "Weather", icon: "cloud.sun.fill", iconColor: .blue, renderingMode: .multicolor)
                        }
                        NavigationLink {
                            MusicSettingsView()
                        } label: {
                            ListRowView(title: "Music", icon: "music.note", iconColor: .red)
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
            }
        }
    }
}

struct ListRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let iconColor: Color
    let renderingMode: SymbolRenderingMode
    
    init(title: String, icon: String, iconColor: Color? = nil, renderingMode: SymbolRenderingMode = .monochrome) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor ?? Color.gray
        self.renderingMode = renderingMode
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30, alignment: .leading)
                .symbolRenderingMode(renderingMode)
                .foregroundStyle(iconColor)
            Text(NSLocalizedString(title, comment: ""))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
        }
    }
}

struct TrendRowView: View {
    let icon: String
    let accent: Color
    let value: Int
    let maxValue: Int
    
    var progress: Double {
        return Double(value) / Double(maxValue)
    }
    
    var body: some View {
        Circle()
            .stroke(Material.thick, lineWidth: 4)
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
}
