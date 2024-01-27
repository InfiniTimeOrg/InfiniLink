//
//  StepWeeklyGraph.swift
//  InfiniLink
//
//  Created by Alex Emry on 11/10/21.
//  
//
	

import Foundation
import SwiftUI
import SwiftUICharts

struct StepWeeklyChart: View {
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.managedObjectContext) var viewContext
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<StepCounts>
	@Binding var stepCountGoal: Int
	
	func getStepCounts() -> [BarChartDataPoint] {
		var dataPoints = [BarChartDataPoint]()
		var calendar = Calendar.autoupdatingCurrent
		calendar.firstWeekday = 1
		let today = calendar.startOfDay(for: Date())
		var week = [Date]()
		if let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today) {
			for n in 0...6 {
				if let day = calendar.date(byAdding: .day, value: n, to: thisWeek.start) {
					week += [day]
					let shortFormatter = DateFormatter()
					shortFormatter.dateFormat = "EEEEE"
					let longFormatter = DateFormatter()
					longFormatter.dateFormat = "EEEE"
					let color = ColourStyle(colour: .blue)
					dataPoints.append(BarChartDataPoint(value: 0, xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: day, colour: color))
					
					for i in chartPoints {
						if calendar.isDate(i.timestamp!, inSameDayAs: day) {
							dataPoints[n] = BarChartDataPoint(value: Double(i.steps), xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: i.timestamp!, colour: color)
						}
					}
				}
			}
		}
		return dataPoints
	}
	
	func getChartData() -> BarChartData {
		
		let metadata   = ChartMetadata(title: "Steps This Week")
		
		let gridStyle  = GridStyle(numberOfLines: 5,
								   lineColour   : Color(.lightGray).opacity(0.25),
								   lineWidth    : 1)
		
		let chartStyle = BarChartStyle(infoBoxPlacement   : .floating,
									   markerType         : .none,
									   xAxisGridStyle     : gridStyle,
									   xAxisLabelPosition : .bottom,
									   xAxisLabelsFrom    : .dataPoint(rotation: .degrees(-90)),
//									   xAxisTitle         : "Day of Week",
									   yAxisGridStyle     : gridStyle,
									   yAxisLabelPosition : .leading,
									   yAxisNumberOfLabels: 5,
//									   yAxisTitle         : "Steps",
									   baseline           : .zero,
									   topLine            : .maximum(of: Double(stepCountGoal)))
		
		return BarChartData(dataSets  : BarDataSet(dataPoints: getStepCounts()),
									metadata  : metadata,
									barStyle  : BarStyle(barWidth: 0.9,
														 cornerRadius: CornerRadius(top: 10, bottom: 0),
														 colourFrom: .dataPoints,
														 colour: ColourStyle(colour: .blue)),
									chartStyle: chartStyle)
	}
	
	var body: some View {
		let chartData = getChartData()
		BarChart(chartData: chartData)
			.yAxisPOI(chartData: chartData, markerName: "Step Goal", markerValue: Double(stepCountGoal), labelColour: Color(.lightGray).opacity(0.25), lineColour: Color(.lightGray).opacity(0.25), strokeStyle: StrokeStyle.init(dash: [5]))
			.floatingInfoBox(chartData: chartData)
			.touchOverlay(chartData: chartData)
			.xAxisLabels(chartData: chartData)
			.yAxisLabels(chartData: chartData)
            .animation(.none)
//			.id(chartData.id)
	}
}

#Preview {
    StepWeeklyChart(stepCountGoal: .constant(10000))
        .frame(height: 250)
}
