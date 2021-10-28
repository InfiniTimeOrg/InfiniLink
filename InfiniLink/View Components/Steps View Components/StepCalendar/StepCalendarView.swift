//
//  StepCalendarView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/27/21.
//  
//  modified from this github gist by @mecid: https://gist.github.com/mecid/f8859ea4bdbd02cf5d440d58e936faec
    

import SwiftUI

struct StepCalendarView: View {
	@Environment(\.calendar) var calendar
	
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
	private var existingStepCounts: FetchedResults<StepCounts>
	
	@Binding var currentPercentage: Float
	@Binding var stepCountGoal: Int

	private var year: DateInterval {
		calendar.dateInterval(of: .year, for: Date())!
	}
	private var month: DateInterval {
		calendar.dateInterval(of: .month, for: Date())!
	}

	var body: some View {
		CalendarView() { date in
			ZStack{
				Text("30")
					.hidden()
					.padding(8)
					.padding(.vertical, 2)
					.overlay(
						Text(String(self.calendar.component(.day, from: date)))
					)
					.overlay(
						setStepHistory(date: date)
					)
			}
		}
	}
	
	func setStepHistory(date: Date) -> AnyView {
		if Calendar.current.isDateInToday(date) {
			return AnyView(StepProgressGauge(currentPercentage: $currentPercentage, stepCountGoal: $stepCountGoal, calendar: true))
		} else {
			for stepCount in existingStepCounts {
				if Calendar.current.compare(stepCount.timestamp!, to: date, toGranularity: .day) == .orderedSame {
					return AnyView(CalendarGauge(stepCountGoal: $stepCountGoal, oldCount: stepCount.steps))
				}
			}
			return AnyView(CalendarGauge(stepCountGoal: $stepCountGoal, oldCount: 0))
		}
	}
}
