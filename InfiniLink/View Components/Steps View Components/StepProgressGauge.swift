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
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
	private var existingStepCounts: FetchedResults<StepCounts>
	@Binding var stepCountGoal: Int
	var calendar: Bool
	@State var backgroundColor = Color.clear
	
	func getStepHistory(date: Date) -> Int32 {
		for stepCount in existingStepCounts {
			if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) { //(stepCount.timestamp!, to: date, toGranularity: .day) == .orderedSame {
				return stepCount.steps
			}
		}
		return 0
	}
	
	var body: some View {
		VStack {
			ZStack {
				Circle()
					.stroke(lineWidth: calendar ? 3.0 : 10.0)
					.opacity(0.3)
					.foregroundColor(Color.gray)
				Circle()
					.trim(from: 0.0, to: CGFloat(min((Float(getStepHistory(date: Date()))/Float(stepCountGoal)), 1.0)))
					.stroke(style: StrokeStyle(lineWidth: calendar ? 5.0 : 20.0, lineCap: .round, lineJoin: .round))
					.foregroundColor(Color.blue)
					.rotationEffect(Angle(degrees: 270.0))
					//.animation(.linear)
				if !calendar {
					VStack {
						Text(String(getStepHistory(date: Date())))
							.font(.largeTitle)
							.bold()
						Text("\(NSLocalizedString("steps_goal", comment: "")): \(stepCountGoal)")
					}
				}
			}
			if !calendar {
				Spacer()
			}
		}
	}
}

struct CalendarGauge: View {
	@Binding var stepCountGoal: Int
	let oldCount: Int32
	
	func calculatePercentage() -> Float {
		return (Float(oldCount) / Float(stepCountGoal))
	}
	
	func setBackgroundColor() -> Color {
		if calculatePercentage() >= 100 {
			return Color.blue
		} else {
			return Color.clear
		}
	}
	
	var body: some View {
		ZStack {
			Circle()
				.stroke(lineWidth: 3.0)
				.opacity(0.3)
				.foregroundColor(Color.gray)
				.background(setBackgroundColor())
			Circle()
				.trim(from: 0.0, to: CGFloat(min(calculatePercentage(), 1.0)))
				.stroke(style: StrokeStyle(lineWidth: 5.0, lineCap: .round, lineJoin: .round))
				.foregroundColor(Color.blue)
				.rotationEffect(Angle(degrees: 270.0))
				.animation(.linear)
		}
	}
}
