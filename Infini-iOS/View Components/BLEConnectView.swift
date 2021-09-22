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
		
			Spacer()
		}
	}
}

struct ConnectView_Previews: PreviewProvider {
	static var previews: some View {
		Connect()
			.environmentObject(BLEManager())
	}
}
