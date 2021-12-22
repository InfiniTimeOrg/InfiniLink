//
//  SideMenu.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/12/21.
//

import SwiftUI

struct SideMenu: View {
	
	@ObservedObject var pageSwitcher: PageSwitcher = PageSwitcher.shared
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	
	func changePage(newPage: Page) {
		pageSwitcher.currentPage = newPage
		withAnimation() {
			pageSwitcher.showMenu = false
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Button(action: {changePage(newPage: .home)}) {
					Image(systemName: "house.fill")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//						.imageScale(.large)
					Text(NSLocalizedString("home", comment: ""))
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 100)
			HStack {
				Button(action: {changePage(newPage: .steps)}) {
					Image(systemName: "figure.walk")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//						.imageScale(.large)
					Text(NSLocalizedString("steps", comment: ""))
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			HStack {
				Button(action: {changePage(newPage: .status)}) {
					Image(systemName: "waveform.path.ecg")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//						.imageScale(.large)
					Text(NSLocalizedString("charts", comment: ""))
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
			.padding(.top, 20)

			HStack {
				Button(action: {changePage(newPage: .dfu)}) {
					Image(systemName: "arrow.up.doc")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//						.imageScale(.large)
					Text(NSLocalizedString("update", comment: ""))
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			HStack {
				Button(action: {changePage(newPage: .settings)}) {
					Image(systemName: "gear")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//						.imageScale(.large)
					Text(NSLocalizedString("settings", comment: ""))
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			Spacer()
//			HStack {
				Button(action: {
					// if pinetime is connected, button says disconnect, and disconnects on press
					if bleManager.isConnectedToPinetime {
						self.bleManager.disconnect()
					} else {
						// show connect sheet if pinetime is not connected and autoconnect is disabled,
						// OR if pinetime is not connected and autoconnect is enabled, BUT there's no UUID saved for autoconnect
						if BLEAutoconnectManager.shared.shouldDisplayConnectSheet() {
							pageSwitcher.showMenu = false
							SheetManager.shared.sheetSelection = .connect
							SheetManager.shared.showSheet = true
						} else {
							// if autoconnect is on and no pinetime is connected, start the scan which will autoconnect if that PT advertises
							bleManager.startScanning()
						}
					}
				}) {
					if bleManager.isSwitchedOn {
						Image(systemName: "radiowaves.right")
							.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
//							.imageScale(.large)
						Text(bleManager.isConnectedToPinetime ? NSLocalizedString("disconnect", comment: "") : (bleManager.isScanning ? NSLocalizedString("scanning", comment: "") : NSLocalizedString("connect", comment: "")))
							.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
							.padding(5)
					} else {
						Text(NSLocalizedString("bluetooth_off", comment: ""))
							.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
							.padding(5)
					}
				}.disabled((bleManager.isScanning && autoconnect) || !bleManager.isSwitchedOn)
				.padding(.vertical, 30)			
		}
			.padding(20)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(colorScheme == .dark ? Color.darkGray : Color.white)
	}
}
