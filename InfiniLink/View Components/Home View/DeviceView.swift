//
//  DeviceView.swift
//  InfiniLink
//
//  Created by John Stanley on 11/16/21.
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("autoconnectToDevice") var autoconnectToDevice: Bool = false
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("showDisconnectAlert") var showDisconnectConfDialog: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var currentUptime: TimeInterval!
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var dateFormatter = DateComponentsFormatter()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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
                        NavigationLink(destination: StepView()) {
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
                                    Text(bleManagerVal.heartBPM.description)
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
                    NavigationLink(destination: RenameView().navigationBarBackButtonHidden()) {
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

enum RowModifierStyle {
    case capsule
    case standard
}

struct RowModifier: ViewModifier {
    var style: RowModifierStyle
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(style == .capsule ? 40 : 15)
    }
}

#Preview {
    NavigationView {
        DeviceView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = true
            }
    }
}
