//
//  SettingsView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/15/21.
//  
//
    

import Foundation
import SwiftUI

struct Settings_Page: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	@AppStorage("watchNotifications") var watchNotifications: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("batteryNotification") var batteryNotification: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	@AppStorage("heartChartFill") var heartChartFill: Bool = true
	@AppStorage("batChartFill") var batChartFill: Bool = true
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	@State private var changedName: String = ""
	private var nameManager = DeviceNameManager()
	@State private var resultMessage = ""
	
	var body: some View {
		VStack {
			Text("Settings")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			Form {
				Section(header: Text("Connect Options")) {
					Toggle("Autoconnect to PineTime", isOn: $autoconnect)
					Button {
						autoconnectUUID = bleManager.setAutoconnectUUID
						print(autoconnectUUID)
					} label: {
						Text("Use Current Device for Autoconnect")
					}.disabled(!autoconnect || (autoconnectUUID == bleManager.infiniTime.identifier.uuidString))
					Button {
						autoconnectUUID = ""
						print(autoconnectUUID)
					} label: {
						Text("Clear Autoconnect Device")
					}.disabled(!autoconnect || autoconnectUUID.isEmpty)
				}
				Section(header: Text("Device Name")) {
					TextField("Enter New Name", text: $changedName)
					Button {
						UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
						resultMessage = nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
						changedName = ""
					} label: {
						Text("Rename Device")
					}
				}

				Section(header: Text("Notifications")) {
					Toggle("Enable Watch Notifications", isOn: $watchNotifications)
					Toggle("Notify about Low Battery", isOn: $batteryNotification)
					Button {
						SheetManager.shared.sheetSelection = .notification
						SheetManager.shared.showSheet = true
					} label: {
						Text("Send Notification to PineTime")
					}.disabled(!watchNotifications || !bleManager.isConnectedToPinetime)
				}
				Section(header: Text("Graph Styles")) {
					Toggle("Filled HRM Graph", isOn: $heartChartFill)
					Toggle("Filled Battery Graph", isOn: $batChartFill)
				}
				Section(header: Text("Graph Data")) {
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text("Clear All HRM Chart Data"))
					}
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text("Clear All Battery Chart Data"))
					}
				}
				Section(header: Text("Links")) {
					Link("Infini-iOS GitHub", destination: URL(string: "https://github.com/xan-m/Infini-iOS")!)
					Link("Matrix", destination: URL(string: "https://matrix.to/#/@xanm:matrix.org")!)
					Link("Mastodon", destination: URL(string: "https://fosstodon.org/@xanm")!)
					Link("InfiniTime Firmware Releases", destination: URL(string: "https://github.com/JF002/InfiniTime/releases")!)
				}
				Section(header: Text("Donations")) {
					Link("PayPal Donation", destination: URL(string: "https://paypal.me/alexemry")!)
				}
			}
		}
	}
}
