//
//  StepsSettingsSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheet: View {
	
	@ObservedObject var addDateValue = NumbersOnly()
	@ObservedObject var setStepGoal = NumbersOnly()
	let persistenceManager = StepCountPersistenceManager()
	@AppStorage("stepCountGoal") var stepCountGoal = 10000
	@State var selectedDate: Date = Date()
	
	func readyToSubmit(value: String) -> Bool {
		if value == "" {
			return true
		} else {
			return false
		}
	}
	
	var body: some View {
		VStack {
			SheetCloseButton()
			Text("Step Count Settings")
				.font(.largeTitle)
				.padding()
			Text("Change Step Count Goal")
			TextField("Step Goal", text: $setStepGoal.value)
				.padding()
				.keyboardType(.decimalPad)
			Button {
				stepCountGoal = Int(setStepGoal.value)!
			} label: {
				Text("Submit New Step Goal")
			}.disabled(readyToSubmit(value: setStepGoal.value))
			
			Text("Manually Add Step Count")
				.font(.title)
				.padding()
			DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
			TextField("Number of Steps", text: $addDateValue.value)
				.padding()
				.keyboardType(.decimalPad)
			Button {
				persistenceManager.setStepCount(steps: Int(addDateValue.value)!, arbitrary: true, date: selectedDate)
			} label: {
				Text("Submit Count")
			}.disabled(readyToSubmit(value: addDateValue.value))
		}
	}
}

class NumbersOnly: ObservableObject {
	@Published var value = "" {
		didSet {
			let filtered = value.filter { $0.isNumber }
			
			if value != filtered {
				value = filtered
			}
		}
	}
}
