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
	var calendar: Bool
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(lineWidth: calendar ? 3.0 : 10.0)
				.opacity(0.3)
				.foregroundColor(Color.gray)
			Circle()
				.trim(from: 0.0, to: CGFloat(min(currentPercentage, 1.0)))
				.stroke(style: StrokeStyle(lineWidth: calendar ? 5.0 : 20.0, lineCap: .round, lineJoin: .round))
				.foregroundColor(Color.blue)
				.rotationEffect(Angle(degrees: 270.0))
				.animation(.linear)
			if !calendar {
				VStack {
					Text(String(bleManager.stepCount))
						.font(.largeTitle)
						.bold()
					Text("Step Goal: \(stepCountGoal)")
				}
			}
		}
	}
}

struct CalendarGauge: View {
	@Binding var stepCountGoal: Int
	let oldCount: Int32
	
	func calculatePercentage() -> Float {
		return Float(Int(oldCount) / stepCountGoal)
	}
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(lineWidth: 3.0)
				.opacity(0.3)
				.foregroundColor(Color.gray)
			Circle()
				.trim(from: 0.0, to: CGFloat(min(calculatePercentage(), 1.0)))
				.stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
				.foregroundColor(Color.blue)
				.rotationEffect(Angle(degrees: 270.0))
				.animation(.linear)
		}
	}
}
