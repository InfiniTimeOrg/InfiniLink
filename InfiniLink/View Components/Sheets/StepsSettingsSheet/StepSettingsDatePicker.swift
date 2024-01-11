//
//  StepSettingsDatePicker.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheetDatePicker: View {
    @Environment(\.presentationMode) var presMode
    @ObservedObject var healthKitManager = HealthKitManager()
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
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("manually_add_step_count", comment: ""))
                .font(.title2.weight(.semibold))
            HStack {
                Text(NSLocalizedString("select_date", comment: "") + ":")
                    .fontWeight(.medium)
                Spacer()
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
            }
            TextField(NSLocalizedString("enter_number_of_steps", comment: ""), text: $addDateValue.value)
                .padding()
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
                .keyboardType(.numberPad)
            Button {
                healthKitManager.writeSteps(date: selectedDate, stepsToAdd: Double(addDateValue.value)!)
                StepCountPersistenceManager().setStepCount(steps: Int32(addDateValue.value)!, arbitrary: true, date: selectedDate)
                presMode.wrappedValue.dismiss()
            } label: {
                Text(NSLocalizedString("submit_count", comment: ""))
            }
            .buttonStyle(NeumorphicButtonStyle(bgColor: .blue))
            .opacity(readyToSubmit(value: addDateValue.value) ? 0.5 : 1.0)
            .disabled(readyToSubmit(value: addDateValue.value))
        }
        .padding()
	}
}

#Preview {
    StepSettingsSheetDatePicker()
}
