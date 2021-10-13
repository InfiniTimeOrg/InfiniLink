//
//  ChartSettingsSheetSlider.swift
//  Infini-iOS
//
//  Created by Alex Emry on 10/13/21.
//  
//
    

import SwiftUI

struct ChartSettingsSheetSliders: View {
	@Binding var chartRangeState: ChartManager.DateSelectionState
	
	var body: some View{
		List{
			Slider(value: $chartRangeState.hours, in: 0...23, step: 1) {
				Text("Hours")
			} minimumValueLabel: {
				Text("Hours: " + String(format: "%.0f", chartRangeState.hours))
			} maximumValueLabel: {
				Text("")
			}
			
			Slider(value: $chartRangeState.days, in: 0...6, step: 1) {
				Text("Days")
			}  minimumValueLabel: {
				Text("Days: " + String(format: "%.0f", chartRangeState.days))
			} maximumValueLabel: {
				Text("")
			}

			Slider(value: $chartRangeState.weeks, in: 0...4, step: 1) {
				Text("Weeks")
			}  minimumValueLabel: {
				Text("Weeks: " + String(format: "%.0f", chartRangeState.weeks))
			} maximumValueLabel: {
				Text("")
			}
		}
		.listStyle(.insetGrouped)
	}
}
