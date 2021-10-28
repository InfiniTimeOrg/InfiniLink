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
	@State var selection: Int = 2
	
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
				TabView(selection: $selection) {
					StepProgressGauge(currentPercentage: $stepGoalPercentage, stepCountGoal: $stepCountGoal, calendar: false)
							.padding()
							.frame(width: (g.size.width / 1.3), height: (g.size.width / 1.3), alignment: .center)

						.tabItem {
							Image(systemName: "chart.bar.xaxis")
							Text("Week")
						}
						.padding(.top)
						.tag(1)
					StepProgressGauge(currentPercentage: $stepGoalPercentage, stepCountGoal: $stepCountGoal, calendar: false)
							.padding()
							.frame(alignment: .center)
						.tabItem {
							Image(systemName: "figure.walk")
							Text("Current")
						}
						.padding(.top)
						.tag(2)
					StepCalendarView(currentPercentage: $stepGoalPercentage, stepCountGoal: $stepCountGoal)
							.padding()
							.frame(alignment: .center)
						.tabItem {
							Image(systemName: "calendar")
							Text("Month")
						}
						.padding(.top)
						.tag(3)
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
}
