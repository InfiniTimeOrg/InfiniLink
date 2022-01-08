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
<<<<<<< HEAD
		Text(NSLocalizedString("change_step_count_goal", comment: ""))
			.font(.title2)
			.padding()
		TextField(NSLocalizedString("enter_step_goal", comment: ""), text: $setStepGoal.value)
=======
		TextField("Enter Step Goal", text: $setStepGoal.value)
>>>>>>> d1c98d0 (Removed some superfluous padding and labels from the step adjustment sheet for better usability on small screens)
			.textFieldStyle(.roundedBorder)
			.padding()
			.keyboardType(.numberPad)
		Button {
			stepCountGoal = Int(setStepGoal.value)!
		} label: {
			Text(NSLocalizedString("submit_new_step_goal", comment: ""))
		}.disabled(readyToSubmit(value: setStepGoal.value))
			.padding()
	}
}
