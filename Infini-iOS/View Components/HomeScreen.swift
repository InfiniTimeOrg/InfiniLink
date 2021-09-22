//
//  HomeScreen.swift
//  HomeScreen
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI

struct HomeScreen: View {
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("autoconnect") var autoconnect: Bool = false
	
	var body: some View{
		VStack{
			Text("Infini-iOS")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			
			Text("Firmware Version: " + BLEDeviceInfo.shared.firmware)
				.font(.title)
			Text("Model Number: " + BLEDeviceInfo.shared.modelNumber)
				.font(.title)
			Text("Software Revision: " + BLEDeviceInfo.shared.softwareRevision)
				.font(.title)
			Text("Hardware revision: " + BLEDeviceInfo.shared.hardwareRevision)
				.font(.title)
			Text("Manufacturer: " + BLEDeviceInfo.shared.manufacturer)
				.font(.title)
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
