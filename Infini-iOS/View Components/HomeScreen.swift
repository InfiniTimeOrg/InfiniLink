//
//  HomeScreen.swift
//  HomeScreen
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI

struct HomeScreen: View {
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
	
	
	var body: some View {
		return VStack{
			Text("Infini-iOS")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			Form{
				Section(header: Text("Device Name")) {
					Text(deviceInfo.deviceName)
				}
				Section(header: Text("Device Information")) {
					if !bleManager.isConnectedToPinetime {
						Text("Firmware Version: ")
						Text("Model: ")
					} else {
						Text("Firmware Version: " + deviceInfo.firmware)
						Text("Model: " + deviceInfo.modelNumber)
					}
				}
			}
			Spacer()

			
			if bleManager.isConnectedToPinetime {
				Button(action: {
					self.bleManager.disconnect()
				}) {
					Text("Disconnect from PineTime")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(colorScheme == .dark ? Color.darkGray : Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
						.padding(.bottom)
				}
			} else {
				Button(action: {
					if !autoconnect{
						SheetManager.shared.showSheet = true
					} else {
						bleManager.startScanning()
					}
				}) {
					Text("Connect to PineTime")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(colorScheme == .dark ? Color.darkGray : Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
						.padding(.bottom)
				}.disabled(bleManager.isScanning)
			}
		}
	}
}


