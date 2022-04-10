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
	@ObservedObject var pageSwitcher = PageSwitcher.shared
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
			Text(NSLocalizedString("settings", comment: ""))
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			List {
				Section(header: Text(NSLocalizedString("connect_options", comment: ""))) {
					Toggle(NSLocalizedString("autoconnect_to_pinetime", comment: ""), isOn: $autoconnect)
					Button {
						autoconnectUUID = bleManager.setAutoconnectUUID
						DebugLogManager.shared.debug(error: "\(NSLocalizedString("autoconnect_device_uuid", comment: "")): \(autoconnectUUID)", log: .app, date: Date())
					} label: {
						Text(NSLocalizedString("use_current_device_for_autoconnect", comment: ""))
					}.disabled(!bleManager.isConnectedToPinetime || (!autoconnect || (autoconnectUUID == bleManager.infiniTime.identifier.uuidString)))
					Button {
						autoconnectUUID = ""
						DebugLogManager.shared.debug(error: NSLocalizedString("autoconnect_device_cleared", comment: ""), log: .app, date: Date())
					} label: {
						Text(NSLocalizedString("clear_autoconnect_device", comment: ""))
					}.disabled(!autoconnect || autoconnectUUID.isEmpty)
				}
				Section(header: Text(NSLocalizedString("device_name", comment: ""))) {
					Text(NSLocalizedString("current_device_name", comment: "") + deviceInfo.deviceName)
					TextField(NSLocalizedString("enter_new_name", comment: ""), text: $changedName)
						.disabled(!bleManager.isConnectedToPinetime)
					Button {
						UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
						nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
						changedName = ""
					} label: {
						Text(NSLocalizedString("rename_device", comment: ""))
					}.disabled(!bleManager.isConnectedToPinetime)
				}
				
				Section(header: Text(NSLocalizedString("firmware_update_downloads", comment: ""))) {
					Toggle(NSLocalizedString("show_newer_versions_only", comment: ""), isOn: $showNewDownloadsOnly)
				}
				

				Section(header: Text(NSLocalizedString("notifications", comment: ""))) {
					Toggle(NSLocalizedString("enable_watch_notifications", comment: ""), isOn: $watchNotifications)
					Toggle(NSLocalizedString("notify_about_low_battery", comment: ""), isOn: $batteryNotification)
					Button {
						SheetManager.shared.sheetSelection = .notification
						SheetManager.shared.showSheet = true
					} label: {
						Text(NSLocalizedString("send_notification_to_pinetime", comment: ""))
					}.disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
				}
				Section(header: Text(NSLocalizedString("graph_styles", comment: ""))) {
					Toggle(NSLocalizedString("filled_hrm_graph", comment: ""), isOn: $heartChartFill)
					Toggle(NSLocalizedString("filled_battery_graph", comment: ""), isOn: $batChartFill)
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

				// MARK: logging
				Section(header: Text(NSLocalizedString("debug_mode", comment: ""))) {
					Toggle(NSLocalizedString("enable_debug_mode", comment: ""), isOn: $debugMode)
					if debugMode {
						Button {
							pageSwitcher.currentPage = Page.debug
						} label: {
							Text(NSLocalizedString("debug_logs", comment: ""))
						}
					}
				}
				Section(header: Text(NSLocalizedString("links", comment: ""))) {
					Link("InfiniLink GitHub", destination: URL(string: "https://github.com/xan-m/InfiniLink")!)
					Link("InfiniTime Firmware Releases", destination: URL(string: "https://github.com/JF002/InfiniTime/releases")!)
				}
			}
			.listStyle(.insetGrouped)
		}
	}
}
