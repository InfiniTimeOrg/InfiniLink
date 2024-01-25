//
//  DeviceView.swift
//  InfiniLink
//
//  Created by John Stanley on 11/16/21.
//

import CoreLocation
import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    @ObservedObject var weatherController = WeatherController.shared
    
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("autoconnectToDevice") var autoconnectToDevice: Bool = false
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("showDisconnectAlert") var showDisconnectConfDialog: Bool = false
    @AppStorage("weatherData") var weatherData: Bool = true
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var currentUptime: TimeInterval!
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var dateFormatter = DateComponentsFormatter()
    private let locationManager = CLLocationManager()
    
    var icon: String {
        switch bleManagerVal.weatherInformation.icon {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 4, 5:
            return "cloud.rain.fill"
        case 6:
            return "cloud.bolt.rain.fill"
        case 7:
            return "cloud.snow.fill"
        case 8:
            return "cloud.fog.fill"
        default:
            return "slash.circle"
        }
    }
    var backgroundGradient: LinearGradient {
        switch 0 {
        case 0:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing)
        case 2:
            return LinearGradient(colors: [.blue, .lightGray, .yellow], startPoint: .leading, endPoint: .trailing)
        case 3:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing)
        case 4, 5:
            return LinearGradient(colors: [.gray, .lightGray], startPoint: .leading, endPoint: .trailing)
        case 6:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing)
        case 7, 8:
            return LinearGradient(colors: [.white, .lightGray], startPoint: .leading, endPoint: .trailing)
        default:
            return LinearGradient(colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // To stop content from scrolling under safe area
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.clear)
            ScrollView {
                VStack(spacing: 10) {
                    VStack(spacing: 20) {
                        Image("PineTime-1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(5)
                            .frame(width: 110, height: 110)
                        VStack(alignment: .center, spacing: 12) {
                            if !bleManager.isConnectedToPinetime {
                                Text(NSLocalizedString("not_connected", comment: ""))
                                    .foregroundColor(.primary)
                                    .font(.title.weight(.bold))
                                HStack(spacing: 7) {
                                    ProgressView()
                                    Text(NSLocalizedString("connecting", comment: ""))
                                }
                                .foregroundColor(.gray)
                            } else {
                                Text(deviceInfo.deviceName == "" ? "InfiniTime" : deviceInfo.deviceName)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .bold()
                                    .font(.title.weight(.bold))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    Divider()
                        .padding(.vertical, 10)
                        .padding(.horizontal, -16)
                    // Use Lazy Grids?
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            NavigationLink(destination: BatteryView()) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(NSLocalizedString("battery_tilte", comment: ""))
                                            .font(.title3.weight(.semibold))
                                        Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            NavigationLink(destination: DFUView()) {
                                HStack {
                                    Text(NSLocalizedString("software_update", comment: ""))
                                        .multilineTextAlignment(.leading)
                                        .font(.title3.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.primary)
                                .cornerRadius(20)
                            }
                        }
                        HStack(spacing: 8) {
                            NavigationLink(destination: StepView().navigationBarHidden(true)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(NSLocalizedString("step_count", comment: ""))
                                            .font(.title3.weight(.semibold))
                                        Text("\(bleManagerVal.stepCount)")
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            NavigationLink(destination: HeartView()) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(NSLocalizedString("heart_rate", comment: ""))
                                            .font(.title3.weight(.semibold))
                                        Text(String(format: "%.0f", bleManagerVal.heartBPM) + " " + NSLocalizedString("bpm", comment: "BPM"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.medium))
                                }
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }
                        if weatherData {
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(NSLocalizedString("weather", comment: ""))
                                            .font(.headline)
                                        if bleManagerVal.loadingWeather {
                                            Text(NSLocalizedString("loading", comment: "Loading..."))
                                        } else {
                                            if (UnitTemperature.current == .celsius && deviceData.chosenWeatherMode == "System") || deviceData.chosenWeatherMode == "Metric" {
                                                Text(String(Int(bleManagerVal.weatherInformation.temperature)) + "°" + "C")
                                                    .font(.title.weight(.semibold))
                                            } else {
                                                Text(String(Int(bleManagerVal.weatherInformation.temperature * 1.8 + 32)) + "°" + "F")
                                                    .font(.title.weight(.semibold))
                                            }
                                        }
                                    }
                                    .font(.title.weight(.semibold))
                                    Spacer()
                                    VStack {
                                        if bleManagerVal.loadingWeather {
                                            Image(systemName: "circle.slash")
                                        } else {
                                            Image(systemName: icon)
                                        }
                                    }
                                    .font(.title.weight(.medium))
                                }
                            }
                            .padding()
                            .background(backgroundGradient)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            Spacer()
                                .frame(height: 6)
                        }
                    }
                    if DownloadManager.shared.updateAvailable {
                        NavigationLink(destination: DFUView()) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(NSLocalizedString("software_update_available", comment: "Software Update Available"))
                                        .font(.title2.weight(.semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.body.weight(.medium))
                                }
                                Text(DownloadManager.shared.updateVersion)
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                Spacer()
                                    .frame(height: 5)
                                Text(DownloadManager.shared.updateBody)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(4)
                            }
                            .foregroundColor(.primary)
                            .modifier(RowModifier(style: .standard))
                        }
                    }
                    VStack {
                        NavigationLink(destination: RenameView()) {
                            HStack {
                                Text(NSLocalizedString("name", comment: ""))
                                Text(deviceInfo.deviceName)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .modifier(RowModifier(style: .capsule))
                        }
                        .opacity(bleManager.isConnectedToPinetime ? 1.0 : 0.5)
                        .disabled(!bleManager.isConnectedToPinetime)
                        HStack {
                            Text(NSLocalizedString("software_version", comment: ""))
                            Spacer()
                            Text(deviceInfo.firmware)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("model_name", comment: ""))
                            Text(deviceInfo.modelNumber)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("last_disconnect", comment: ""))
                            Spacer()
                            if UptimeManager.shared.lastDisconnect != nil {
                                Text(uptimeManager.dateFormatter.string(from: uptimeManager.lastDisconnect))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .modifier(RowModifier(style: .capsule))
                        HStack {
                            Text(NSLocalizedString("uptime", comment: ""))
                            Spacer()
                            if currentUptime != nil {
                                Text((dateFormatter.string(from: currentUptime) ?? ""))
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .modifier(RowModifier(style: .capsule))
                    }
                    .onReceive(timer, perform: { _ in
                        if uptimeManager.connectTime != nil {
                            currentUptime = -uptimeManager.connectTime.timeIntervalSinceNow
                        }
                    })
                    Spacer()
                        .frame(height: 6)
                    VStack {
                        if bleManager.isConnectedToPinetime {
                            Toggle(isOn: $bleManager.autoconnectToDevice) {
                                Text(NSLocalizedString("autoconnect_to_this", comment: "") + " \(deviceInfo.modelNumber)")
                            }.onChange(of: bleManager.autoconnectToDevice) { newValue in
                                autoconnect = bleManager.autoconnectToDevice
                                if bleManager.autoconnectToDevice == false {
                                    autoconnectUUID = ""
                                } else {
                                    autoconnectUUID = bleManager.setAutoconnectUUID
                                }
                            }
                            .modifier(RowModifier(style: .capsule))
                        }
                        Toggle(NSLocalizedString("enable_watch_notifications", comment: ""), isOn: $watchNotifications)
                            .modifier(RowModifier(style: .capsule))
                        Toggle(NSLocalizedString("notify_about_low_battery", comment: ""), isOn: $batteryNotification)
                            .modifier(RowModifier(style: .capsule))
                        Button {
                            SheetManager.shared.sheetSelection = .notification
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text(NSLocalizedString("send_notification_to", comment: "") + " \(deviceInfo.modelNumber)")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                        .opacity(!watchNotifications || !bleManager.isConnectedToPinetime ? 0.5 : 1.0)
                        .disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                        Button {
                            BLEWriteManager.init().sendLostNotification()
                        } label: {
                            Text(NSLocalizedString("find_lost_device", comment: "") + " \(deviceInfo.modelNumber)")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                        .opacity(!watchNotifications || !bleManager.isConnectedToPinetime ? 0.5 : 1.0)
                        .disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                    }
                    Spacer()
                        .frame(height: 6)
                    VStack {
                        Button {
                            showDisconnectConfDialog.toggle()
                        } label: {
                            Text(NSLocalizedString("disconnect", comment: "") + " \(deviceInfo.modelNumber)")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.red)
                                .font(.body.weight(.semibold))
                                .modifier(RowModifier(style: .capsule))
                        }
                    }
                }
                .padding()
                .onAppear {
                    // check if an update has been made in the last //24 hours
                    if DownloadManager.shared.lastCheck == nil || DownloadManager.shared.lastCheck.timeIntervalSince(Date()) <  -86400 {
                        DownloadManager.shared.getDownloadUrls(currentVersion: BLEDeviceInfo.shared.firmware)
                        DownloadManager.shared.lastCheck = Date()
                    } else {
                        DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: BLEDeviceInfo.shared.firmware)
                    }
                }
            }
        }
    }
}

enum RowModifierStyle {
    case capsule
    case standard
}

struct RowModifier: ViewModifier {
    var style: RowModifierStyle
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray.opacity(0.15))
            .foregroundColor(.primary)
            .cornerRadius(style == .capsule ? 40 : 15)
    }
}

#Preview {
    NavigationView {
        DeviceView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = true
                BLEManagerVal.shared.firmwareVersion = "1.13.0"
            }
    }
}
