//
//  ContentView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/5/21.
//

import SwiftUI
import CoreData

struct ContentView: View {

	@ObservedObject var bleManager = BLEManager()
	
	var body: some View {
		VStack (spacing: 10){
			
			
			if bleManager.isConnectedToPinetime {
				Text("InfiniTime Services")
					.font(.largeTitle)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(30)

				HStack (spacing: 10){
					Text("Heart Rate: ")
						.font(.title)
					Text(bleManager.heartBPM)
						.font(.title)
						.foregroundColor(.red)
				}
				
				HStack (spacing: 10){
					Text("Battery Level: ")
						.font(.title)
					Text(bleManager.batteryLevel)
						.font(.title)
						.foregroundColor(.red)
				}
			} else {
				Text("Available Devices")
					.font(.largeTitle)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(30)
				List(bleManager.peripherals) { peripheral in
					HStack {
						Button(action: {
							self.bleManager.deviceToConnect = peripheral.id
							print(peripheral.id)
							//print(self.bleManager.peripheralDictionary[peripheral.id]?.name)
							self.bleManager.connect(peripheral: self.bleManager.peripheralDictionary[peripheral.id]!)
						}) {
							Text(peripheral.name)
						}
					}
				}
			}
			
			Spacer()
			
			HStack {
				VStack (spacing:10) {
					Button(action: {
						self.bleManager.startScanning()
					}) {
						Text("Scan and Connect")
					}
					Button(action: {
						self.bleManager.stopScanning()
					}) {
						Text("Stop Scanning")
					}
					Button(action: {
						self.bleManager.disconnect()
					}) {
						Text("Disconnect")
					}
					Button(action: {
						self.bleManager.sendNotification(notification: "Testing Notifications")
					}) {
						Text("Test Notifications")
					}
				}.padding()
				
				Spacer()
				
				VStack (spacing:10) {
					Text("STATUS")
						.font(.headline)

					
					if bleManager.isSwitchedOn {
						Text("Bluetooth is switched on")
							.foregroundColor(.green)
					}
					else {
						Text("Bluetooth is NOT switched on")
							.foregroundColor(.red)
					}
					
					if bleManager.isConnectedToPinetime {
						Text("PineTime is connected")
							.foregroundColor(.green)
					}
					else {
						Text("PineTime is not connected")
							.foregroundColor(.red)
					}
					
					if bleManager.isScanning {
						Text("Scanning")
							.foregroundColor(.green)
					}
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
