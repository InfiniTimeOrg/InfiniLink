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
	let oldestPoint: Date?

	var body: some View {
        ScrollView {
            VStack {
                DatePicker(
                    NSLocalizedString("start_date", comment: ""),
                    selection: $chartRangeState.startDate,
                    in: (oldestPoint ?? oneMonthAgo)...today,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .modifier(RowModifier(style: .capsule))
                DatePicker(
                    NSLocalizedString("end_date", comment: ""),
                    selection: $chartRangeState.endDate,
                    in: chartRangeState.startDate...today,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .modifier(RowModifier(style: .capsule))
            }
            .padding(.top, 8)
		}
	}
}
