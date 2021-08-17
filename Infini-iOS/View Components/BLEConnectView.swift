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
	@State var scanOrStopScan: Bool = true

	var body: some View {
		
		VStack (){
			Text("Available Devices")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
				//.padding(.bottom, 30)
			List(bleManager.peripherals) { peripheral in
				HStack {
					Button(action: {
						self.bleManager.deviceToConnect = peripheral.peripheralHash
						self.bleManager.connect(peripheral: self.bleManager.peripheralDictionary[peripheral.peripheralHash]!)
					}) {
						Text(peripheral.name)
					}
					Spacer()
					Text("RSSI: " + String(peripheral.rssi))
				}
			}
		
			Spacer()
	
			let autoconnect = UserDefaults.standard.object(forKey: "autoconnect") as? Bool ?? true
			if autoconnect {
				Button(action: {
					self.bleManager.startScanning()
				}) {
					Text("Autoconnect")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
				}

			} else {
				if scanOrStopScan {
					Button(action: {
						self.bleManager.startScanning()
						self.scanOrStopScan.toggle()
					}) {
						Text("Scan")
							.padding()
							.padding(.vertical, 7)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color.gray)
							.foregroundColor(Color.white)
							.cornerRadius(10)
							.padding(.horizontal, 20)
					}
				} else {
				
					Button(action: {
						self.bleManager.stopScanning()
						self.scanOrStopScan.toggle()
					}) {
						Text("Stop Scanning")
							.padding()
							.padding(.vertical, 7)
							.frame(maxWidth: .infinity, alignment: .center)
							.background(Color.gray)
							.foregroundColor(Color.white)
							.cornerRadius(10)
							.padding(.horizontal, 20)
					}
				}
			}
		}
	}
}
