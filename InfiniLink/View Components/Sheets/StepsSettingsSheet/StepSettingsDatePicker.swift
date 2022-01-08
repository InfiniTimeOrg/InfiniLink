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
<<<<<<< HEAD
<<<<<<< HEAD
		Text(NSLocalizedString("manually_add_step_count", comment: ""))
			.font(.title2)
			.padding()
		DatePicker(NSLocalizedString("select_date", comment: ""), selection: $selectedDate, displayedComponents: [.date])
			.padding()
		TextField(NSLocalizedString("enter_number_of_steps", comment: ""), text: $addDateValue.value)
=======
		DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
			.padding(.horizontal)
		TextField("Enter Number of Steps", text: $addDateValue.value)
>>>>>>> d1c98d0 (Removed some superfluous padding and labels from the step adjustment sheet for better usability on small screens)
=======
		DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
			.padding(.horizontal)
		TextField("Enter Number of Steps", text: $addDateValue.value)
=======
		Text(NSLocalizedString("manually_add_step_count", comment: ""))
			.font(.title2)
			.padding()
		DatePicker(NSLocalizedString("select_date", comment: ""), selection: $selectedDate, displayedComponents: [.date])
			.padding()
		TextField(NSLocalizedString("enter_number_of_steps", comment: ""), text: $addDateValue.value)
>>>>>>> main
>>>>>>> d738921 (resolving git issue)
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

