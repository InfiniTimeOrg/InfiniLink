//
//  StepSettingsGoalChange.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheetGoalChange: View {
    @Environment(\.presentationMode) var presMode
    
	@ObservedObject var setStepGoal = NumbersOnly()
    @ObservedObject var bleFSHandler = BLEFSHandler.shared
    
	@AppStorage("stepCountGoal") var stepCountGoal = 10000
    
    init() {
        setStepGoal.value = String(stepCountGoal)
    }
	
	var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("change_step_goal", comment: ""))
                .font(.title2.weight(.semibold))
            TextField(NSLocalizedString("enter_step_goal", comment: ""), text: $setStepGoal.value)
                .padding()
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
                .keyboardType(.numberPad)
            Button {
                bleFSHandler.readSettings { settings in
                    // Get up to date settings
                    // let settings = settings
                    
                    // TODO: write settings to watch
                    stepCountGoal = Int(setStepGoal.value)!
                }
                
                presMode.wrappedValue.dismiss()
            } label: {
                Text(NSLocalizedString("submit_new_step_goal", comment: ""))
                    .modifier(NeumorphicButtonModifer(bgColor: .blue))
            }
            .opacity(setStepGoal.value.isEmpty ? 0.5 : 1.0)
            .disabled(setStepGoal.value.isEmpty)
        }
        .padding()
	}
}

#Preview {
    StepSettingsSheetGoalChange()
}
