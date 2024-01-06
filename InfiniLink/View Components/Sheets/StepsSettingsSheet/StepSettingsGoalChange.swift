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
    
    init() {
        setStepGoal.value = String(stepCountGoal)
    }
	
	var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("change_step_goal", comment: ""))
                .font(.title2.weight(.semibold))
            TextField(NSLocalizedString("enter_step_goal", comment: ""), text: $setStepGoal.value)
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(Capsule())
                .keyboardType(.numberPad)
            Button {
                stepCountGoal = Int(setStepGoal.value)!
            } label: {
                Text(NSLocalizedString("submit_new_step_goal", comment: ""))
            }
            .buttonStyle(NeumorphicButtonStyle(bgColor: .blue))
            .opacity(readyToSubmit(value: setStepGoal.value) ? 0.5 : 1.0)
            .disabled(readyToSubmit(value: setStepGoal.value))
        }
        .padding()
	}
}

#Preview {
    StepSettingsSheetGoalChange()
}
