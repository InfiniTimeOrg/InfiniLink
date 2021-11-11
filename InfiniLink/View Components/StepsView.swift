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
	@AppStorage("stepCountGoal") var stepCountGoal = 10000
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<StepCounts>
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
					Button {
						SheetManager.shared.sheetSelection = .stepSettings
						SheetManager.shared.showSheet = true
					} label: {
						Image(systemName: "gear")
							.imageScale(.large)
							.padding(.vertical)
					}
					Spacer()
				}
				TabView(selection: $selection) {
					StepWeeklyChart(stepCountGoal: $stepCountGoal)
							.padding()
						.tabItem {
							Image(systemName: "chart.bar.xaxis")
							Text("Week")
						}
						.padding(.top)
						.tag(1)
					StepProgressGauge(stepCountGoal: $stepCountGoal, calendar: false)
							.padding()
							.frame(width: (g.size.width / 1.3), height: (g.size.width / 1.3), alignment: .center)
						.tabItem {
							Image(systemName: "figure.walk")
							Text("Current")
						}
						.padding(.top)
						.tag(2)
					StepCalendarView(stepCountGoal: $stepCountGoal)
							.padding()
							.frame(alignment: .init(horizontal: .center, vertical: .top))
						.tabItem {
							Image(systemName: "calendar")
							Text("Month")
						}
						.padding(.top)
						.tag(3)
				}
			}
		}
	}
}
