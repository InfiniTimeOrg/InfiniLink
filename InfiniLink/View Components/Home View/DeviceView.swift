//
//  DeviceView.swift
//  InfiniLink
//
//  Created by John Stanley on 11/16/21.
//

import SwiftUI

struct DeviceInfo: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section() {
            VStack(spacing: 5) {
                Image("PineTime-1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .frame(width: 110, height: 110)
                
                Spacer()
                VStack(alignment: .center) {
                    if !bleManager.isConnectedToPinetime {
                        Text(NSLocalizedString("not_connected", comment: ""))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .bold()
                            .font(.system(size: 24))
                        Text(NSLocalizedString("tap_to_connect", comment: ""))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 12))
                    } else {
                        Text(deviceInfo.deviceName)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .bold()
                            .font(.system(size: 24))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(5)
        }
        .listRowBackground(Color.clear)
    }
}

struct DeviceView: View {
    
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @ObservedObject var uptimeManager = UptimeManager.shared
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("autoconnectToDevice") var autoconnectToDevice: Bool = false
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State var currentUptime: TimeInterval!
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var dateFormatter = DateComponentsFormatter()
    
    
    
    var body: some View {
        return VStack {
            List() {
                DeviceInfo()
                
                Section() {
                    NavigationLink(destination: DFUView()) {
                        Text(NSLocalizedString("software_update", comment: ""))
                    }
                }
                
                Section() {
                    NavigationLink(destination: RenameView()) {
                        HStack {
                            Text(NSLocalizedString("name", comment: ""))
                            Text(deviceInfo.deviceName)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                    }.disabled(!bleManager.isConnectedToPinetime)
                    HStack {
                        Text(NSLocalizedString("software_version", comment: ""))
                        Text(deviceInfo.firmware)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                    }
                    HStack {
                        Text(NSLocalizedString("model_name", comment: ""))
                        Text(deviceInfo.modelNumber)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                    }
                    NavigationLink(destination: BatteryView()) {
                        HStack {
                            Text(NSLocalizedString("battery_tilte", comment: ""))
                            Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        }
                    }
                    HStack {
                        Text(NSLocalizedString("last_disconnect", comment: ""))
                        if UptimeManager.shared.lastDisconnect != nil {
                            Text(uptimeManager.dateFormatter.string(from: uptimeManager.lastDisconnect))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    HStack {
                        Text(NSLocalizedString("uptime", comment: ""))
                        if currentUptime != nil {
                            Text((dateFormatter.string(from: currentUptime) ?? ""))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }.onReceive(timer, perform: { _ in
                    if uptimeManager.connectTime != nil {
                        currentUptime = -uptimeManager.connectTime.timeIntervalSinceNow
                    }
                })
                
                Section() {
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
                    }
                    Toggle(NSLocalizedString("enable_watch_notifications", comment: ""), isOn: $watchNotifications)
                    Toggle(NSLocalizedString("notify_about_low_battery", comment: ""), isOn: $batteryNotification)
                    Button {
                        SheetManager.shared.sheetSelection = .notification
                        SheetManager.shared.showSheet = true
                    } label: {
                        Text(NSLocalizedString("send_notification_to", comment: "") + " \(deviceInfo.modelNumber)")
                    }.disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                }
                
                Section() {
                    Button {
                        bleManager.disconnect()
                    } label: {
                        Text(NSLocalizedString("disconnect", comment: "") + " \(deviceInfo.modelNumber)")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitle(Text(NSLocalizedString("my_device", comment: "")).font(.subheadline), displayMode: .inline)
    }
}
