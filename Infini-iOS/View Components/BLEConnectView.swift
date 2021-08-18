//
//  BLEView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/11/21.
//

import Foundation
import SwiftUI

struct Connect: View {
	
	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	@Environment(\.presentationMode) var presentation
	@State var scanOrStopScan: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	
	init(){
		UITableView.appearance().backgroundColor = .clear
	}

	var body: some View {
		
		VStack (){
			Text("Available Devices")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
				.onAppear {
					bleManager.startScanning()
				}
			List(bleManager.peripherals) { peripheral in
				HStack {
					Button(action: {
						self.bleManager.deviceToConnect = peripheral.peripheralHash
						if !self.bleManager.isConnectedToPinetime {
							self.bleManager.connect(peripheral: self.bleManager.peripheralDictionary[peripheral.peripheralHash]!)
						}
						presentation.wrappedValue.dismiss()
					}) {
						Text(peripheral.name)
					}
					Spacer()
					Text("RSSI: " + String(peripheral.rssi))
				}
			}
		
			Spacer()/*
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
			}*/
		}
	}
}

struct ConnectView_Previews: PreviewProvider {
	static var previews: some View {
		Connect()
			.environmentObject(PageSwitcher())
			.environmentObject(BLEManager())
	}
}
