//
//  BLEView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/11/21.
//

import Foundation
import SwiftUI

struct Connect: View {
	
	@EnvironmentObject var bleManager: BLEManager

	var body: some View {
		
		VStack (spacing: 10){
			Text("Available Devices")
				.font(.largeTitle)
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(30)
			List(bleManager.peripherals) { peripheral in
				HStack {
					Button(action: {
						self.bleManager.deviceToConnect = peripheral.peripheralHash
						self.bleManager.connect(peripheral: self.bleManager.peripheralDictionary[peripheral.peripheralHash]!)
					}) {
						Text(peripheral.name)
					}
					Text(String(peripheral.rssi))
				}
			}
		
		Spacer()
		
		
			Button(action: {
				self.bleManager.startScanning()
			}) {
				Text("Scan and Connect")
					.padding(10)
			}
			.background(Color.gray)
			.foregroundColor(Color.white)
			.cornerRadius(5)
			Button(action: {
				self.bleManager.stopScanning()
			}) {
				Text("Stop Scanning")
					.padding(10)
			}
			.background(Color.gray)
			.foregroundColor(Color.white)
			.cornerRadius(5)
			Button(action: {
				self.bleManager.disconnect()
			}) {
				Text("Disconnect")
					.padding(10)
			}
			.background(Color.gray)
			.foregroundColor(Color.white)
			.cornerRadius(5)
		}.padding()
	}
}
