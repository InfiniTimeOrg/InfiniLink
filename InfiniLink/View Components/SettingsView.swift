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
	
	@State private var changedName: String = ""
	private var nameManager = DeviceNameManager()
	@State private var deviceName = ""
	
	var body: some View {
		VStack {
			List {
                                
                Section(header: Text(NSLocalizedString("app_settings", comment: ""))
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                            
                    NavigationLink(destination: SettingsChosenThemeView(chosenTheme: $deviceDataForSettings.chosenTheme)) {
                        HStack {
                            Text(NSLocalizedString("app_theme", comment: ""))
                            Spacer()
                            Text(deviceData.chosenTheme)
                                .foregroundColor(.secondary)
                        }
                    }
                                
                    NavigationLink(destination: CustomizeFavoritesView()) {
                        Text(NSLocalizedString("customize_favorites", comment: ""))
                    }
                    Toggle(NSLocalizedString("enable_debug_mode", comment: ""), isOn: $debugMode)
                    if debugMode {
                        NavigationLink(destination: DebugView()) {
                            Text(NSLocalizedString("debug_logs", comment: ""))
                        }
                    }
                }
				
				Section(header: Text(NSLocalizedString("firmware_update_downloads", comment: ""))) {
					Toggle(NSLocalizedString("show_newer_versions_only", comment: ""), isOn: $showNewDownloadsOnly)
				}
				

                Section(header: Text(NSLocalizedString("graph_styles", comment: ""))) {
					Toggle(NSLocalizedString("filled_hrm_graph", comment: ""), isOn: $heartChartFill)
					Toggle(NSLocalizedString("filled_battery_graph", comment: ""), isOn: $batChartFill)
				}
                
                if autoconnectUUID != "" {
                    Section(header: Text(NSLocalizedString("connect_options", comment: ""))) {
                        Button {
                            autoconnectUUID = ""
                            bleManager.autoconnectToDevice = false
                            DebugLogManager.shared.debug(error: NSLocalizedString("autoconnect_device_cleared", comment: ""), log: .app, date: Date())
                        } label: {
                            Text(NSLocalizedString("clear_autoconnect_device", comment: ""))
                        }.disabled(!autoconnect || autoconnectUUID.isEmpty)
                    }
                }
                
				Section(header: Text(NSLocalizedString("graph_data", comment: ""))) {
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
					}) {
						(Text(NSLocalizedString("clear_all_hrm_chart_data", comment: "")))
					}
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text(NSLocalizedString("clear_all_battery_chart_data", comment: "")))
					}
				}
				
				Section(header: Text(NSLocalizedString("onboarding_information", comment: ""))) {
					
					Button {
						SheetManager.shared.sheetSelection = .onboarding
						SheetManager.shared.showSheet = true
					} label: {
						Text(NSLocalizedString("open_onboarding_page", comment: ""))
					}
					Button {
						SheetManager.shared.sheetSelection = .whatsNew
						SheetManager.shared.showSheet = true
					} label: {
						Text(NSLocalizedString("whats_new_page_this_version", comment: ""))
					}
				}
                
                Section(header: Text(NSLocalizedString("links", comment: ""))
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                    Link("InfiniLink GitHub", destination: URL(string: "https://github.com/InfiniTimeOrg/InfiniLink")!)
                    Link("InfiniTime Firmware Releases", destination: URL(string: "https://github.com/InfiniTimeOrg/InfiniTime/releases")!)
                }
                
			}
			.listStyle(.insetGrouped)
		}
	}
}
