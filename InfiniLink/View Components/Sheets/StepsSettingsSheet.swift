//
//  StepsSettingsSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/11/21.
//  
//
    

import SwiftUI

struct StepSettingsSheet: View {
    @Environment(\.presentationMode) var presMode
    
    @ObservedObject var healthKitManager = HealthKitManager()
    @ObservedObject var addDateValue = NumbersOnly()
    
    @State var selectedDate: Date = Date()
	
	var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(NSLocalizedString("add_steps", comment: ""))
                    .font(.title.bold())
                Spacer()
                SheetCloseButton()
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(NSLocalizedString("select_date", comment: "") + ":")
                            .fontWeight(.medium)
                        Spacer()
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    }
                    TextField(NSLocalizedString("enter_number_of_steps", comment: ""), text: $addDateValue.value)
                        .padding()
                        .background(Material.regular)
                        .clipShape(Capsule())
                        .keyboardType(.numberPad)
                    Button {
                        healthKitManager.writeSteps(date: selectedDate, stepsToAdd: Double(addDateValue.value)!)
                        StepCountPersistenceManager().setStepCount(steps: Int32(addDateValue.value)!, arbitrary: true, date: selectedDate)
                        presMode.wrappedValue.dismiss()
                    } label: {
                        Text(NSLocalizedString("submit_count", comment: ""))
                            .modifier(NeumorphicButtonModifer(bgColor: .blue))
                    }
                    .opacity(addDateValue.value.isEmpty ? 0.5 : 1.0)
                    .disabled(addDateValue.value.isEmpty)
                }
                .padding()
            }
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

#Preview {
    StepSettingsSheet()
}
