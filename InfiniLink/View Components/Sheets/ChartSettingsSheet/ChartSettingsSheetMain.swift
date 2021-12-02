//
//  ChartSettingsSheet.swift
//  InfiniLink
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
	var chartPoints: FetchedResults<ChartDataPoint>
	
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
			Divider()
				.padding(.horizontal)
			VStack {
				if chartManager.currentChart == .battery {
					Toggle("Filled Battery Graph", isOn: $batChartFill)
						.padding(.horizontal)
						.frame(maxWidth: .infinity)
					Divider()
						.padding(.horizontal)
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text("Clear All Battery Chart Data"))
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding()
				} else {
					Toggle("Filled HRM Graph", isOn: $heartChartFill)
						.padding(.horizontal)
						.frame(maxWidth: .infinity)
					Divider()
						.padding(.horizontal)
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
					}) {
						(Text("Clear All HRM Chart Data"))
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding()
				}
			}
			Divider()
				.padding(.horizontal)
			Text("Select Date Range")
//				.font(.title2)
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
			Picker("Date Range Selection", selection: $chartRangeState.dateRangeSelection) {
				Text("Show All").tag(0)
				Text("Sliders").tag(1)
				Text("Select Dates").tag(2)
			}.pickerStyle(.segmented)
				.padding(.bottom)
				.padding(.horizontal)
			switch chartRangeState.dateRangeSelection {
			case 0:
				Text("All Data Selected")
					.padding()
					.font(.title)
			case 1:
				ChartSettingsSheetSliders(chartRangeState: self.$chartRangeState)
			case 2:
				if chartPoints.count > 0 {
					ChartSettingsSheetDatePicker(chartRangeState: self.$chartRangeState, oldestPoint: chartPoints[0].timestamp!)
				} else {
					ChartSettingsSheetDatePicker(chartRangeState: self.$chartRangeState, oldestPoint: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? (Date() - 2419200))
				}
			default:
				EmptyView()
			}
		}
		Spacer()
		.onDisappear(){
			setDateRange()
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
