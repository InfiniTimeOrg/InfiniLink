//
//  StepsSettingsSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheet: View {
	
	var body: some View {
		VStack (alignment: .leading) {
			SheetCloseButton()
			Text("Step Count Settings")
				.font(.largeTitle)
				.padding()
				.padding(.bottom, 20)
			StepSettingsSheetGoalChange()
			Divider()
				.padding()
			StepSettingsSheetDatePicker()
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
