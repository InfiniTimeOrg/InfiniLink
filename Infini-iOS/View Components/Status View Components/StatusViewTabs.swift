//
//  StatusViewTabs.swift
//  Infini-iOS
//
//  Created by xan-m on 8/18/21.
//  
//
    

import Foundation
import SwiftUI

struct StatusTabs: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@State var trueIfHeart = true
	
	var body: some View{
		VStack {
			if !bleManager.isConnectedToPinetime {
				Text("Disconnected")
					.foregroundColor(Color.white)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding()
					.background(Color.darkGray)
					.cornerRadius(5)
					.font(.title)
					.padding(.horizontal, 10)
			} else {
				HStack {
					Button (action: {
						self.trueIfHeart = true
					}) {
					(Text(Image(systemName: "heart"))
						.foregroundColor(Color.pink) +
					Text(": " + String(format: "%.0f", bleManager.heartBPM))
						.foregroundColor(Color.white))
						.frame(maxWidth:.infinity, alignment: .center)
						.padding()
						.background(trueIfHeart ? Color.darkGray : Color.darkestGray)
						.cornerRadius(5)
						.font(.title)
					}.padding(.leading, 10)
					Button (action: {
						self.trueIfHeart = false
					}) {
					(Text(Image(systemName: "battery.100"))
						.foregroundColor(Color.green) +
						Text(": " + String(format: "%.0f", bleManager.batteryLevel))
						.foregroundColor(Color.white))
						.frame(maxWidth: .infinity, alignment: .center)
						.padding()
						.background(trueIfHeart ? Color.darkestGray : Color.darkGray)
						.cornerRadius(5)
						.font(.title)
					}
					.padding(.trailing, 10)
				}
				if trueIfHeart {
					HeartChart()
				} else {
					BatteryChart()
				}
			}
		}
	}
}
