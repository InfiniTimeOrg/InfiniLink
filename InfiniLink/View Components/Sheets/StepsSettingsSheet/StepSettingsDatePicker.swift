//
//  StepSettingsDatePicker.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheetDatePicker: View {
	@ObservedObject var addDateValue = NumbersOnly()
	@State var selectedDate: Date = Date()
	
	func readyToSubmit(value: String) -> Bool {
		if value == "" {
			return true
		} else {
			return false
		}
	}
	
	var body: some View {
		DatePicker(NSLocalizedString("select_date", comment: ""), selection: $selectedDate, displayedComponents: [.date])
			.padding()
		TextField(NSLocalizedString("enter_number_of_steps", comment: ""), text: $addDateValue.value)
			.textFieldStyle(.roundedBorder)
			.padding(.horizontal)
			.keyboardType(.numberPad)
		Button {
			StepCountPersistenceManager().setStepCount(steps: Int(addDateValue.value)!, arbitrary: true, date: selectedDate)
		} label: {
			Text(NSLocalizedString("submit_count", comment: ""))
		}.disabled(readyToSubmit(value: addDateValue.value))
			.padding()
	}
}

