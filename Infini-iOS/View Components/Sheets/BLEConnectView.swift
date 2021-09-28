//
//  BLEView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct Connect: View {
	
	@ObservedObject var pageSwitcher: PageSwitcher = PageSwitcher.shared
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.presentationMode) var presentation
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""

	var body: some View {
		SheetCloseButton()
		VStack (){
			if bleManager.isSwitchedOn {
				Text("Available Devices")
					.font(.largeTitle)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
					.onAppear {
						bleManager.startScanning()
					}
			} else {
				Text("Available Devices")
					.font(.largeTitle)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
				Text("Waiting for Bluetooth")
					.font(.title)
					.padding()
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			List(bleManager.peripherals) { peripheral in
				let deviceName = DeviceNameManager.init().getName(deviceUUID: peripheral.stringUUID)
				HStack {
					Button(action: {
						self.bleManager.deviceToConnect = peripheral.peripheralHash
						self.bleManager.connect(peripheral: self.bleManager.peripheralDictionary[peripheral.peripheralHash]!)
						presentation.wrappedValue.dismiss()
					}) {
						if deviceName == "" {
							Text(peripheral.name)
						} else {
							Text(deviceName)
						}
					}
					Spacer()
					Text("RSSI: " + String(peripheral.rssi))
				}
			}
		
			Spacer()
		}.onDisappear {
			if bleManager.isScanning {
				bleManager.stopScanning()
			}
		}
	}
}

struct ConnectView_Previews: PreviewProvider {
	static var previews: some View {
		Connect()
			.environmentObject(BLEManager())
	}
}
