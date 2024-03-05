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
	@Binding var stepCountGoal: Int

	private var year: DateInterval {
		calendar.dateInterval(of: .year, for: Date())!
	}
	private var month: DateInterval {
		calendar.dateInterval(of: .month, for: Date())!
	}

	var body: some View {
		VStack {
			CalendarView { date in
				ZStack {
					setStepHistory(date: date)
					Text("30")
						.hidden()
						.padding(8)
						.padding(.vertical, 3)
						.overlay(
							Text(String(self.calendar.component(.day, from: date)))
						)
				}
			}
		}
	}
	
	func getStepHistory(date: Date) -> Int32 {
		for stepCount in existingStepCounts {
			if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) { //(stepCount.timestamp!, to: date, toGranularity: .day) == .orderedSame {
				return stepCount.steps
			}
		}
		return 0
	}
	
	func setStepHistory(date: Date) -> AnyView {
		let steps = getStepHistory(date: date)
		return AnyView(CalendarGauge(stepCountGoal: $stepCountGoal, oldCount: steps))
	}
}

#Preview {
    StepCalendarView(stepCountGoal: .constant(1000))
        .padding(30)
}
