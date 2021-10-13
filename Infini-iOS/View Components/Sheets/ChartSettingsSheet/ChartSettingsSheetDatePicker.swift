//
//  ChartSettingsSheetDatePicker.swift
//  Infini-iOS
//
//  Created by Alex Emry on 10/13/21.
//  
//
    

import SwiftUI

struct ChartSettingsSheetDatePicker: View {
	let today = Date()
	let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? (Date() - 2419200)
	
	@Binding var chartRangeState: ChartManager.DateSelectionState
	let oldestPoint: Date?

	var body: some View {
		List {
			DatePicker(
				"Start Date",
				selection: $chartRangeState.startDate,
				in: (oldestPoint ?? oneMonthAgo)...today,
				displayedComponents: [.date, .hourAndMinute]
			)
			DatePicker(
				"End Date",
				selection: $chartRangeState.endDate,
				in: chartRangeState.startDate...today,
				displayedComponents: [.date, .hourAndMinute]
			)
		}.listStyle(.insetGrouped)
	}
}
