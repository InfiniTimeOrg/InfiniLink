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
		Text("Manually Add Step Count")
			.font(.title)
			.padding()
		DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
			.padding()
		TextField("Number of Steps", text: $addDateValue.value)
			.padding()
			.keyboardType(.decimalPad)
		Button {
			StepCountPersistenceManager().setStepCount(steps: Int(addDateValue.value)!, arbitrary: true, date: selectedDate)
		} label: {
			Text("Submit Count")
		}.disabled(readyToSubmit(value: addDateValue.value))
			.padding()
	}
}

