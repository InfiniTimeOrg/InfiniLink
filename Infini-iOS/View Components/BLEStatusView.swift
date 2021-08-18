//
//  BLEStatusView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/13/21.
//

import Foundation
import SwiftUI

struct DeviceView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	
	var body: some View {
		VStack (spacing: 10){
			Text("InfiniTime Status")
				.font(.largeTitle)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			
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
			
			Spacer()
			if bleManager.isConnectedToPinetime {
				Button(action: {
					self.bleManager.disconnect()
				}) {
					Text("Disconnect from PineTime")
						.padding()
						.padding(.vertical, 7)
						.frame(maxWidth: .infinity, alignment: .center)
						.background(Color.gray)
						.foregroundColor(Color.white)
						.cornerRadius(10)
						.padding(.horizontal, 20)
				}
			} else {
				Text("Disconnected")
					.padding()
					.padding(.vertical, 7)
					.frame(maxWidth: .infinity, alignment: .center)
					.background(Color.darkGray)
					.foregroundColor(Color.gray)
					.cornerRadius(10)
					.padding(.horizontal, 20)
			}
		}//.padding()
	}
}
