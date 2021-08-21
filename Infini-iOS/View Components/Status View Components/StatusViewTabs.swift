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
	@State var trueIfBat = false
	@Environment(\.colorScheme) var colorScheme

	var body: some View{
		VStack {
			HStack {
				Button (action: {
					self.trueIfHeart = true
					self.trueIfBat = false
				}) {
				(Text(Image(systemName: "heart"))
					.foregroundColor(Color.pink) +
				Text(": " + String(format: "%.0f", bleManager.heartBPM))
					.foregroundColor(Color.white))
					.frame(maxWidth:.infinity, alignment: .center)
					.padding()
					.background(colorScheme == .dark ? (trueIfHeart ? Color.darkGray : Color.darkestGray) : (trueIfHeart ? Color.gray : Color.lightGray))
					.cornerRadius(5)
					.font(.title)
				}.padding(.leading, 10)
				Button (action: {
					self.trueIfHeart = false
					self.trueIfBat = true
				}) {
				(Text(Image(systemName: "battery.100"))
					.foregroundColor(Color.green) +
					Text(": " + String(format: "%.0f", bleManager.batteryLevel))
					.foregroundColor(Color.white))
					.frame(maxWidth: .infinity, alignment: .center)
					.padding()
					.background(colorScheme == .dark ? (trueIfBat ? Color.darkGray : Color.darkestGray) : (trueIfBat ? Color.gray : Color.lightGray))
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
