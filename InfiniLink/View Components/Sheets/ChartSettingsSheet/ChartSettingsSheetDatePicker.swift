//
//  ChartSettingsSheetDatePicker.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/13/21.
//  
//
    

import SwiftUI

struct ChartSettingsSheetDatePicker: View {
	let today = Date()
	let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? (Date() - 2419200)
	
	@Binding var chartRangeState: ChartManager.DateSelectionState
	let oldestPoint: Date

	var body: some View {
		List {
			DatePicker(
				NSLocalizedString("start_date", comment: ""),
				selection: $chartRangeState.startDate,
				in: (oldestPoint)...today,
				displayedComponents: [.date, .hourAndMinute]
			)
			DatePicker(
				NSLocalizedString("end_date", comment: ""),
				selection: $chartRangeState.endDate,
				in: chartRangeState.startDate...today,
				displayedComponents: [.date, .hourAndMinute]
			)
		}.listStyle(.insetGrouped)
	}
}
