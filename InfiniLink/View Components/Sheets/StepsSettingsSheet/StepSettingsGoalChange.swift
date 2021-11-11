//
//  StepSettingsGoalChange.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheetGoalChange: View {
	@ObservedObject var setStepGoal = NumbersOnly()
	@AppStorage("stepCountGoal") var stepCountGoal = 10000
	
	func readyToSubmit(value: String) -> Bool {
		if value == "" {
			return true
		} else {
			return false
		}
	}
	
	var body: some View {
		Text("Change Step Count Goal")
			.font(.title2)
			.padding()
		TextField("Enter Step Goal", text: $setStepGoal.value)
			.textFieldStyle(.roundedBorder)
			.padding()
			.keyboardType(.numberPad)
		Button {
			stepCountGoal = Int(setStepGoal.value)!
		} label: {
			Text("Submit New Step Goal")
		}.disabled(readyToSubmit(value: setStepGoal.value))
			.padding()
	}
}
