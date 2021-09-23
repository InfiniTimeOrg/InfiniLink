//
//  TimeRangeTabs.swift
//  TimeRangeTabs
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import SwiftUI

//
//  StatusViewTabs.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/18/21.
//
//
	

import Foundation
import SwiftUI

struct TimeRangeTabs: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var chartManager = ChartManager.shared
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false

	var body: some View{
		HStack {
			// set date range to last hour
			Button (action: {
				chartManager.dateRange = .hour
			}) {
			(Text("Hour")
				.foregroundColor(Color.white))
				.frame(maxWidth: .infinity, alignment: .center)
				.padding()
				.background(colorScheme == .dark ? (chartManager.dateRange == .hour ? Color.darkGray : Color.darkestGray) : (chartManager.dateRange == .hour ? Color.gray : Color.lightGray))
				.cornerRadius(5)
				.font(.title)
			}
			.padding(.leading, 10)
			
			// set date range to 24 hours
			Button (action: {
				chartManager.dateRange = .day
			}) {
			(Text("Day")
				.foregroundColor(Color.white))
				.frame(maxWidth: .infinity, alignment: .center)
				.padding()
				.background(colorScheme == .dark ? (chartManager.dateRange == .day ? Color.darkGray : Color.darkestGray) : (chartManager.dateRange == .day ? Color.gray : Color.lightGray))
				.cornerRadius(5)
				.font(.title)
			}
			.padding(.horizontal, 3)
			
			// set date range to last week
			Button (action: {
				chartManager.dateRange = .week
			}) {
			(Text("Week")
				.foregroundColor(Color.white))
				.frame(maxWidth: .infinity, alignment: .center)
				.padding()
				.background(colorScheme == .dark ? (chartManager.dateRange == .week ? Color.darkGray : Color.darkestGray) : (chartManager.dateRange == .week ? Color.gray : Color.lightGray))
				.cornerRadius(5)
				.font(.title)
			}
			.padding(.trailing, 10)
		}
	}
}
