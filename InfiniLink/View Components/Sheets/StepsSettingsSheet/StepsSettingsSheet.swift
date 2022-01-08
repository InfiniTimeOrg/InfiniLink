//
//  StepsSettingsSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheet: View {
	@State var pickerState = 0
	
	var body: some View {
		VStack (alignment: .leading) {
			SheetCloseButton()
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> d738921 (resolving git issue)
			Text(NSLocalizedString("steps_settings", comment: ""))
				.font(.largeTitle)
				.padding()
				.padding(.bottom, 20)
<<<<<<< HEAD
=======
>>>>>>> d1c98d0 (Removed some superfluous padding and labels from the step adjustment sheet for better usability on small screens)
=======
>>>>>>> main
>>>>>>> d738921 (resolving git issue)
			Picker("", selection: $pickerState) {
				Text(NSLocalizedString("step_goal", comment: "")).tag(0)
				Text(NSLocalizedString("add_steps", comment: "")).tag(1)
			}.pickerStyle(.segmented)
				.padding(.bottom)
				.padding(.horizontal)
			switch pickerState {
			case 0:
				StepSettingsSheetGoalChange()
			case 1:
				StepSettingsSheetDatePicker()
			default:
				EmptyView()
			}
			Spacer()
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
