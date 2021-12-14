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
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	@AppStorage("lastStatusViewWasHeart") var lastStatusViewWasHeart: Bool = false
	@ObservedObject var chartManager = ChartManager.shared

	var body: some View{
		Picker("Chart", selection: $chartManager.currentChart) {
			Text(NSLocalizedString("heart", comment: "") + String(format: "%.0f", bleManager.heartBPM) + " \(NSLocalizedString("bpm", comment: ""))")
				.tag(ChartManager.chartSelection.heart)
			Text(NSLocalizedString("battery", comment: "") + String(format: "%.0f", bleManager.batteryLevel) + "%")
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
