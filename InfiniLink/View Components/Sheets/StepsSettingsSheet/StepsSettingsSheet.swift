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
			Text("Steps Settings")
				.font(.largeTitle)
				.padding()
				.padding(.bottom, 20)
			Picker("", selection: $pickerState) {
				Text("Step Goal").tag(0)
				Text("Add Steps").tag(1)
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
