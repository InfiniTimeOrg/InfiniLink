//
//  ChartSettingsSheetSlider.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/13/21.
//  
//
    

import SwiftUI

struct ChartSettingsSheetSliders: View {
	@Binding var chartRangeState: ChartManager.DateSelectionState
	
	var body: some View {
        ScrollView {
            VStack {
                Slider(value: $chartRangeState.hours, in: 0...24, step: 1) {
                    Text(NSLocalizedString("hours", comment: ""))
                } minimumValueLabel: {
                    Text(NSLocalizedString("hours", comment: "") + ": " + String(format: "%.0f", chartRangeState.hours))
                } maximumValueLabel: {
                    Text("")
                }
                .modifier(RowModifier(style: .capsule))
                
                Slider(value: $chartRangeState.days, in: 0...7, step: 1) {
                    Text(NSLocalizedString("days", comment: ""))
                }  minimumValueLabel: {
                    Text(NSLocalizedString("days", comment: "") + ": " + String(format: "%.0f", chartRangeState.days))
                } maximumValueLabel: {
                    Text("")
                }
                .modifier(RowModifier(style: .capsule))
                
                Slider(value: $chartRangeState.weeks, in: 0...4, step: 1) {
                    Text(NSLocalizedString("weeks", comment: ""))
                }  minimumValueLabel: {
                    Text(NSLocalizedString("weeks", comment: "") + ": " + String(format: "%.0f", chartRangeState.weeks))
                } maximumValueLabel: {
                    Text("")
                }
                .modifier(RowModifier(style: .capsule))
            }
            .padding(.top, 8)
        }
	}
}
