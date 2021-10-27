//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    

import SwiftUI

struct StepsView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	@State var stepCountGoal = 10000
	@State var stepGoalPercentage: Float = 0.0
	
	
	var body: some View {
		GeometryReader { g in
			VStack {
				HStack {
					Text("Steps")
						.font(.largeTitle)
						.padding(.leading)
						.padding(.vertical)
						.frame(alignment: .leading)
					Spacer()
				}
				ScrollView{
					StepProgressGauge(currentPercentage: $stepGoalPercentage, stepCountGoal: $stepCountGoal, calendar: false)
						.frame(width: (g.size.width / 1.3), height: (g.size.width / 1.3))
						.padding()
					StepCalendarView(currentPercentage: $stepGoalPercentage, stepCountGoal: $stepCountGoal)
						.padding(.horizontal)
				}
			}
			.onChange(of: bleManager.stepCount) { _ in
				stepGoalPercentage = (Float(bleManager.stepCount)/Float(stepCountGoal))
			}
			.onAppear {
				stepGoalPercentage = (Float(bleManager.stepCount)/Float(stepCountGoal))
			}
		}
	}
}
