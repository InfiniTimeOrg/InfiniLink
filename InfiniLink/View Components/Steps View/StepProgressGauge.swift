//
//  StepProgressGauge.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    

import SwiftUI

struct StepProgressGauge: View {
	@ObservedObject var bleManager = BLEManager.shared
	@Binding var currentPercentage: Float
	@Binding var stepCountGoal: Int
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(lineWidth: 10.0)
				.opacity(0.3)
				.foregroundColor(Color.gray)
			Circle()
				.trim(from: 0.0, to: CGFloat(min(currentPercentage, 1.0)))
				.stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
				.foregroundColor(Color.blue)
				.rotationEffect(Angle(degrees: 270.0))
				.animation(.linear)
			VStack {
				Text(String(bleManager.stepCount))
					.font(.largeTitle)
					.bold()
				Text("Step Goal: \(stepCountGoal)")
			}
		}
	}
}
