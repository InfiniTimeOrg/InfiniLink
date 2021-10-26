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
	var stepCountGoal = 10000
	@State var stepGoalPercentage: Float = 0.0
	
	
	var body: some View {
		
		VStack {
			HStack {
				Text("Charts")
					.font(.largeTitle)
					.padding(.leading)
					.padding(.vertical)
					.frame(alignment: .leading)
				Spacer()
			}
//			ProgressView(value: Float(bleManager.stepCount), total: Float(stepCountGoal)) {
//				Text("Step Goal")
//			}
			StepProgressGauge(currentCount: $stepGoalPercentage)
				.padding()
		}
		.onChange(of: bleManager.stepCount) { _ in
			stepGoalPercentage = (Float(bleManager.stepCount)/Float(stepCountGoal))
		}
	}
}
