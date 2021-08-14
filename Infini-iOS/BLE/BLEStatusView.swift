//
//  BLEStatusView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/13/21.
//

import Foundation
import SwiftUI

struct DeviceView: View {
	
	@EnvironmentObject var bleManager: BLEManager
	
	var body: some View {
		VStack (spacing: 10){
			Text("InfiniTime Status")
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
			
			Spacer()
		}
	}
}
