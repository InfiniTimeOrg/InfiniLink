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
	
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.colorScheme) var colorScheme
	
	@AppStorage("watchNotifications") var watchNotifications: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("batteryNotification") var batteryNotification: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = "empty"
	@AppStorage("heartChartFill") var heartChartFill: Bool = true
	@AppStorage("batChartFill") var batChartFill: Bool = true
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	@State private var changedName: String = ""
	private var isEditing = false
	@State private var noCommittedChanges = true
	private var nameManager = DeviceNameManager()
	@State private var resultMessage = ""
	
	var body: some View {
		VStack {//(alignment: .leading){
			Text("Settings")
				.font(.largeTitle)
				.padding()
			Form {
				Section(header: Text("Connect Options")) {
					Toggle("Autoconnect to PineTime", isOn: $autoconnect)
					Button {
						autoconnectUUID = bleManager.setAutoconnectUUID
						print(autoconnectUUID)
					} label: {
						Text("Use Current Device for Autoconnect")
					}.disabled(!autoconnect)
					Button {
						autoconnectUUID = ""
						print(autoconnectUUID)
					} label: {
						Text("Clear Autoconnect Device")
					}.disabled(!autoconnect)
				}
				Section(header: Text("Device Name")) {
				TextField("Enter New Name", text: $changedName, onCommit:  {
						print("piss")
					})
					Button {
						UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
						resultMessage = nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
					} label: {
						Text("Rename Device")
					}
				}

				Section(header: Text("Notifications")) {
					Toggle("Enable Watch Notifications", isOn: $watchNotifications)
					Toggle("Notify about Low Battery", isOn: $batteryNotification)
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
				}
				Section(header: Text("Donations")) {
					Link("PayPal Donation", destination: URL(string: "https://paypal.me/alexemry")!)
				}
			}
		}
	}
}
