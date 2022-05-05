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
                        Text("Not Connected")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .bold()
                            .font(.system(size: 24))
                        //.padding(1)
                        Text("Tap to connect")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.system(size: 12))
                        //Text("")
                        //    .font(.system(size: 12))
                    } else {
                        Text(deviceInfo.deviceName)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .bold()
                            .font(.system(size: 24))
                        //Text("Firmware Version: " + deviceInfo.firmware)
                        //    .foregroundColor(colorScheme == .dark ? .white : .black)
                        //    .font(.system(size: 12))
                        //Text("Model: \(deviceInfo.modelNumber)")
                        //    .foregroundColor(colorScheme == .dark ? .white : .black)
                        //    .font(.system(size: 12))
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
                        Text("Software Update")
                    }
                }
                
                Section() {
                    NavigationLink(destination: RenameView()) {
                        HStack {
                            Text("Name")
                            Text(deviceInfo.deviceName)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            
                        }
                    }.disabled(!bleManager.isConnectedToPinetime)
                    HStack {
                        Text("Software Version")
                        Text(deviceInfo.firmware)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                    }
                    HStack {
                        Text("Model Name")
                        Text(deviceInfo.modelNumber)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                    }
                    NavigationLink(destination: BatteryView()) {
                        HStack {
                            Text("Battery")
                            Text(String(format: "%.0f", bleManager.batteryLevel) + "%")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        }
                    }
                    HStack {
                        Text("Last disconnect")
                        if UptimeManager.shared.lastDisconnect != nil {
                            Text(uptimeManager.dateFormatter.string(from: uptimeManager.lastDisconnect))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    HStack {
                        Text("Uptime")
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
                            Text("Autoconnect to this \(deviceInfo.modelNumber)")
                        }.onChange(of: bleManager.autoconnectToDevice) { newValue in
                            autoconnect = bleManager.autoconnectToDevice
                            if bleManager.autoconnectToDevice == false {
                                autoconnectUUID = ""
                            } else {
                                autoconnectUUID = bleManager.setAutoconnectUUID
                            }
                        }
                    }
                    Toggle("Enable Notifications", isOn: $watchNotifications)
                    Toggle("Notify about Low Battery", isOn: $batteryNotification)
                    Button {
                        SheetManager.shared.sheetSelection = .notification
                        SheetManager.shared.showSheet = true
                    } label: {
                        Text("Send Notification to PineTime")
                    }.disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
                }
                
                Section() {
                    Button {
                        bleManager.disconnect()
                    } label: {
                        Text("Disconnect PineTime")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitle(Text("My Device").font(.subheadline), displayMode: .inline)
    }
}
