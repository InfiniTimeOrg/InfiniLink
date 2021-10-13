//
//  ChartSettingsSheet.swift
//  Infini-iOS
//
//  Created by Alex Emry on 10/13/21.
//  
//


import SwiftUI

struct ChartSettingsSheet: View {
	let chartManager = ChartManager.shared
	@AppStorage("heartChartFill") var heartChartFill: Bool = true
	@AppStorage("batChartFill") var batChartFill: Bool = true
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	@State var chartRangeState: ChartManager.DateSelectionState = ChartManager.DateSelectionState(dateRangeSelection: 1)
	
	func setDateRange() {
		if chartManager.currentChart == .heart {
			chartManager.heartRangeSelectionState = chartRangeState
		} else {
			chartManager.batteryRangeSelectionState = chartRangeState
		}
	}
	
	var body: some View {
		VStack {
			SheetCloseButton()
			VStack {
				if chartManager.currentChart == .battery {
					Toggle("Filled Battery Graph", isOn: $batChartFill)
						.padding()
						.frame(maxWidth: .infinity)
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text("Clear All Battery Chart Data"))
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal)
				} else {
					Toggle("Filled HRM Graph", isOn: $heartChartFill)
						.padding()
						.frame(maxWidth: .infinity)
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
					}) {
						(Text("Clear All HRM Chart Data"))
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal)
				}
			}.padding()
			Text("Select Date Range")
				.font(.title2)
				.padding()
				.frame(alignment: .leading)
			Picker("Date Range Selection", selection: $chartRangeState.dateRangeSelection) {
				Text("Show All").tag(0)
				Text("Sliders").tag(1)
				Text("Select Dates").tag(2)
			}.pickerStyle(.segmented)
				.padding()
			switch chartRangeState.dateRangeSelection {
			case 0:
				EmptyView()
			case 1:
				ChartSettingsSheetSliders(chartRangeState: self.$chartRangeState)
			case 2:
				ChartSettingsSheetDatePicker(chartRangeState: self.$chartRangeState)
			default:
				EmptyView()
			}
		}
		Spacer()
		.onDisappear(){
			setDateRange()
			print()
		}
		.onAppear() {
			if chartManager.currentChart == .heart {
				chartRangeState = chartManager.heartRangeSelectionState
			} else {
				chartRangeState = chartManager.batteryRangeSelectionState
			}
		}
	}
}
