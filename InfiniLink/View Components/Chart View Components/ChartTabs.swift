//
//  StatusViewTabs.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/18/21.
//  
//
    

import Foundation
import SwiftUI

struct StatusTabs: View {
	
	@ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
	@ObservedObject var chartManager = ChartManager.shared

	var body: some View{
		Picker("Chart", selection: $chartManager.currentChart) {
			Text("Heart: " + String(format: "%.0f", bleManagerVal.heartBPM) + " BPM")
				.tag(ChartManager.chartSelection.heart)
			Text("Battery: " + String(format: "%.0f", bleManager.batteryLevel) + "%")
				.tag(ChartManager.chartSelection.battery)
		}
		.pickerStyle(.segmented)
		.onChange(of: chartManager.currentChart) { _ in
			if chartManager.currentChart == .heart {
				lastStatusViewWasHeart = true
			} else {
				lastStatusViewWasHeart = false
			}
		}
	}
}
