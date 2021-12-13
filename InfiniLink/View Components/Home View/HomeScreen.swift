//
//  HomeScreen.swift
//  HomeScreen
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI

struct HomeScreen: View {
	
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
	@ObservedObject var dfuUpdater = DFU_Updater.shared
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var downloadManager = DownloadManager.shared
	@ObservedObject var uptimeManager = UptimeManager.shared
	let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	@State var currentUptime: TimeInterval!
	@State var updateAvailable: Bool = false
	
	@State var renamingDevice: Bool = false
	@State private var changedName: String = ""
	private var nameManager = DeviceNameManager()
	@State private var deviceName = ""
	
	private var dateFormatter = DateComponentsFormatter()
	
	var body: some View {
		return VStack{
			Text("InfiniLink")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			List{
				Section(header: RenameDeviceHeader(renamingDevice: $renamingDevice, fieldText: $changedName)) {
					if renamingDevice {
						TextField(deviceName, text: $changedName, onCommit: {
							nameManager.updateName(deviceUUID: bleManager.infiniTime.identifier.uuidString, name: changedName)
							renamingDevice = false
						})
							.onAppear() {
								deviceName = String(DeviceNameManager().getName(deviceUUID: bleManager.infiniTime.identifier.uuidString).isEmpty ? "InfiniTime" : DeviceNameManager().getName(deviceUUID: bleManager.infiniTime.identifier.uuidString))
							}
					} else {
						Text(deviceInfo.deviceName)
					}
				}
				Section(header: Text(NSLocalizedString("device_information", comment: ""))) {
					if !bleManager.isConnectedToPinetime {
						Text(NSLocalizedString("firmware_version", comment: ""))
						Text(NSLocalizedString("model", comment: ""))
					} else {
						Text(NSLocalizedString("firmware_version", comment: "") + deviceInfo.firmware)
						Text(NSLocalizedString("model", comment: "") + deviceInfo.modelNumber)
							.onAppear() {
								// check if an update has been made in the last 24 hours
								if downloadManager.lastCheck == nil || downloadManager.lastCheck.timeIntervalSince(Date()) <  -86400 {
									downloadManager.getDownloadUrls()
									downloadManager.lastCheck = Date()
								}
							}
					}
				}
				Section(header: Text(NSLocalizedString("update_stats", comment: ""))) {
					if UptimeManager.shared.lastDisconnect == nil {
						Text(NSLocalizedString("last_disconnect", comment: ""))
					} else {
						Text(NSLocalizedString("last_disconnect", comment: "") + uptimeManager.dateFormatter.string(from: uptimeManager.lastDisconnect))
						
					}
					if currentUptime == nil {
						Text(NSLocalizedString("uptime", comment: ""))
					} else {
						Text(NSLocalizedString("uptime", comment: "") + (dateFormatter.string(from: currentUptime) ?? ""))
					}
				}.onReceive(timer, perform: { _ in
					if uptimeManager.connectTime != nil {
						currentUptime = -uptimeManager.connectTime.timeIntervalSinceNow
					}
				})
				Section(header: Text(NSLocalizedString("step_count", comment: ""))) {
					Text(String(bleManager.stepCount))
				}
				Section(header: Text(NSLocalizedString("firmware_updates", comment: ""))) {
					if bleManager.isConnectedToPinetime {
						if self.updateAvailable {
							Button{
								let asset = downloadManager.chooseAsset(response: downloadManager.autoUpgrade)
								dfuUpdater.firmwareFilename = asset.name
								dfuUpdater.firmwareSelected = true
								dfuUpdater.local = false
								DownloadManager.shared.startDownload(url: asset.browser_download_url)
								PageSwitcher.shared.currentPage = .dfu
							} label: {
								Text(NSLocalizedString("firmware_update_is_available", comment: ""))
							}.disabled(!bleManager.isConnectedToPinetime)
						} else {
							Text(NSLocalizedString("no_updates_available", comment: ""))
						}
					} else {
						Text("")
					}
				}
				.onChange(of: downloadManager.downloading) { _ in
					if !downloadManager.downloading {
						if downloadManager.updateAvailable {
							self.updateAvailable = true
						}
					}
				}
			}
			.listStyle(.insetGrouped)
			
			// leaving this section here in case of negative feedback on removing the button.
			
			//			Spacer()
			//			Button(action: {
			//				// if pinetime is connected, button says disconnect, and disconnects on press
			//				if bleManager.isConnectedToPinetime {
			//					self.bleManager.disconnect()
			//				} else {
			//					// show connect sheet if pinetime is not connected and autoconnect is disabled,
			//					// OR if pinetime is not connected and autoconnect is enabled, BUT there's no UUID saved for autoconnect
			//					if !autoconnect || (autoconnect && autoconnectUUID.isEmpty) {
			//						SheetManager.shared.showSheet = true
			//					} else {
			//						// if autoconnect is on and no pinetime is connected, start the scan which will autoconnect if that PT advertises
			//						bleManager.startScanning()
			//					}
			//				}
			//			}) {
			//				Text(bleManager.isConnectedToPinetime ? "Disconnect from PineTime" : (bleManager.isScanning ? "Scanning" : "Connect to PineTime"))
			//					.padding()
			//					.padding(.vertical, 7)
			//					.frame(maxWidth: .infinity, alignment: .center)
			//					.background(colorScheme == .dark ? Color.darkGray : Color.blue)
			//					.foregroundColor(Color.white)
			//					.cornerRadius(10)
			//					.padding(.horizontal, 20)
			//					.padding(.bottom)
			//			}.disabled(bleManager.isScanning && autoconnect) // this button should be disabled and read "Scanning" if autoconnect is enabled and a scan is started. Any other condition when not connected should show the sheet and cover the button
		}
	}
}


