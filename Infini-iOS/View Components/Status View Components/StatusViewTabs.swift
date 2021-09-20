//
//  StatusViewTabs.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/18/21.
//  
//
    

import Foundation
import SwiftUI

struct StatusTabs: View {
	
	@EnvironmentObject var bleManager: BLEManager
	@State var trueIfHeart = true
	@State var trueIfBat = false
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false

	var body: some View{
		VStack {
			HStack {
				Button (action: {
					self.trueIfHeart = true
					self.trueIfBat = false
					lastStatusViewWasHeart = true
				}) {
				(Text(Image(systemName: "heart"))
					.foregroundColor(Color.pink) +
				Text(": " + String(format: "%.0f", bleManager.heartBPM))
					.foregroundColor(Color.white) +
				Text(" BPM")
					.foregroundColor(Color.white)
					.font(.body))
					.frame(maxWidth:.infinity, alignment: .center)
					.padding()
					.background(colorScheme == .dark ? (trueIfHeart ? Color.darkGray : Color.darkestGray) : (trueIfHeart ? Color.gray : Color.lightGray))
					.cornerRadius(5)
					.font(.title)
				}.padding(.leading, 10)
				Button (action: {
					self.trueIfHeart = false
					self.trueIfBat = true
					lastStatusViewWasHeart = false
				}) {
				(Text(Image(systemName: "battery.100"))
					.foregroundColor(Color.green) +
					Text(": " + String(format: "%.0f", bleManager.batteryLevel) + "%")
					.foregroundColor(Color.white))
					.frame(maxWidth: .infinity, alignment: .center)
					.padding()
					.background(colorScheme == .dark ? (trueIfBat ? Color.darkGray : Color.darkestGray) : (trueIfBat ? Color.gray : Color.lightGray))
					.cornerRadius(5)
					.font(.title)
				}
				.padding(.trailing, 10)
			}
			if lastStatusViewWasHeart {
				HeartChart()
					.onAppear() {
						self.trueIfHeart = true
						self.trueIfBat = false
					}
			} else {
				BatteryChart()
					.onAppear() {
						self.trueIfHeart = false
						self.trueIfBat = true
					}
			}
		}

	}
}
