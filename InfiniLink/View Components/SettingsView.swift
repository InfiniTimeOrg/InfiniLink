//
//  SettingsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/15/21.
//
//


import Foundation
import SwiftUI

struct Settings_Page: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @ObservedObject private var deviceDataForSettings: DeviceData = deviceData
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) private var openURL
    
    @AppStorage("watchNotifications") var watchNotifications: Bool = true
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("batteryNotification") var batteryNotification: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @AppStorage("heartChartFill") var heartChartFill: Bool = true
    @AppStorage("batChartFill") var batChartFill: Bool = true
    @AppStorage("debugMode") var debugMode: Bool = false
    @AppStorage("showNewDownloadsOnly") var showNewDownloadsOnly: Bool = false
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    let themes: [String] = ["System", "Light", "Dark"]
    
    @State private var changedName: String = ""
    private var nameManager = DeviceNameManager()
    @State private var deviceName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(NSLocalizedString("settings", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                HStack {
                    if bleManager.isConnectedToPinetime && deviceInfo.firmware != "" {
                        Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25)))
                            .imageScale(.large)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            ScrollView {
                VStack {
                    HStack(spacing: 8) {
                        Menu {
                            Picker("", selection: $deviceDataForSettings.chosenTheme) {
                                ForEach(themes, id: \.self) {
                                    Text($0)
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(NSLocalizedString("app_theme", comment: ""))
                                        .font(.title3.weight(.semibold))
                                    Text(deviceDataForSettings.chosenTheme)
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
                        Menu {
                            Button(action: {
                                if let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniTime") {
                                    openURL(url)
                                }
                            }) {
                                Text("InfiniTime")
                            }
                            Button(action: {
                                if let url = URL(string: "https://github.com/InfiniTimeOrg/InfiniLink") {
                                    openURL(url)
                                }
                            }) {
                                Text("InfiniLink")
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("GitHub")
                                        .font(.title3.weight(.semibold))
                                    Text(NSLocalizedString("links", comment: "Links"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.medium))
                            }
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                    }
                    VStack {
                        Toggle(NSLocalizedString("enable_debug_mode", comment: ""), isOn: $debugMode.animation(.bouncy))
                            .modifier(RowModifier(style: .capsule))
                        if debugMode {
                            NavigationLink(destination: DebugView()) {
                                HStack {
                                    Text(NSLocalizedString("debug_logs", comment: ""))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .modifier(RowModifier(style: .capsule))
                            }
                        }
                    }
                    Toggle(NSLocalizedString("show_newer_versions_only", comment: ""), isOn: $showNewDownloadsOnly)
                        .modifier(RowModifier(style: .capsule))
                        .padding(.top)
                    VStack {
                        Toggle(NSLocalizedString("filled_hrm_graph", comment: ""), isOn: $heartChartFill)
                            .modifier(RowModifier(style: .capsule))
                        Toggle(NSLocalizedString("filled_battery_graph", comment: ""), isOn: $batChartFill)
                            .modifier(RowModifier(style: .capsule))
                    }
                    .padding(.top)
                    if autoconnectUUID != "" {
                        VStack {
                            Button {
                                autoconnectUUID = ""
                                bleManager.autoconnectToDevice = false
                                DebugLogManager.shared.debug(error: NSLocalizedString("autoconnect_device_cleared", comment: ""), log: .app, date: Date())
                            } label: {
                                Text(NSLocalizedString("clear_autoconnect_device", comment: ""))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .modifier(RowModifier(style: .capsule))
                            }
                            .opacity(!autoconnect || autoconnectUUID.isEmpty ? 0.5 : 1.0)
                            .disabled(!autoconnect || autoconnectUUID.isEmpty)
                        }
                        .padding(.top)
                    }
                    VStack {
                        Button(action: {
                            ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
                        }) {
                            Text(NSLocalizedString("clear_all_hrm_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                        Button(action: {
                            ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
                        }) {
                            Text(NSLocalizedString("clear_all_battery_chart_data", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                                .modifier(RowModifier(style: .capsule))
                        }
                    }
                    .padding(.top)
                    VStack {
                        Button {
                            SheetManager.shared.sheetSelection = .onboarding
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text(NSLocalizedString("open_onboarding_page", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                        Button {
                            SheetManager.shared.sheetSelection = .whatsNew
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text(NSLocalizedString("whats_new_page_this_version", comment: ""))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.blue)
                                .modifier(RowModifier(style: .capsule))
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
        }
    }
}
