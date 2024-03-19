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
	@Environment(\.colorScheme) var colorScheme
    
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)]) private var chartPoints: FetchedResults<StepCounts>
    
	@Binding var stepCountGoal: Int
    @State var displayDate = Date()
	
    func getStepCounts(displayWeek: DateInterval?) -> [BarChartDataPoint] {
		var dataPoints = [BarChartDataPoint]()
		var calendar = Calendar.autoupdatingCurrent
		calendar.firstWeekday = 1
		var week = [Date]()
		if let thisWeek = displayWeek {
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
		
        return BarChartData(dataSets  : BarDataSet(dataPoints: getStepCounts(displayWeek: Calendar.autoupdatingCurrent.dateInterval(of: .weekOfYear, for: displayDate))),
									metadata  : metadata,
									barStyle  : BarStyle(barWidth: 0.9,
														 cornerRadius: CornerRadius(top: 10, bottom: 0),
														 colourFrom: .dataPoints,
														 colour: ColourStyle(colour: .blue)),
									chartStyle: chartStyle)
	}
	
	var body: some View {
		let chartData = getChartData()
        
        VStack {
            HStack {
                Button {
                    // Update date here...
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Material.thin)
                        .clipShape(Circle())
                }
                Spacer()
                Text("Weekly Steps")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    // Update date here...
                } label: {
                    Image(systemName: "chevron.right")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Material.thin)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 25)
            BarChart(chartData: chartData)
                .yAxisPOI(chartData: chartData, markerName: "Step Goal", markerValue: Double(stepCountGoal), labelColour: Color(.lightGray).opacity(0.25), lineColour: Color(.lightGray).opacity(0.25), strokeStyle: StrokeStyle.init(dash: [5]))
                .floatingInfoBox(chartData: chartData)
                .touchOverlay(chartData: chartData)
                .xAxisLabels(chartData: chartData)
                .yAxisLabels(chartData: chartData)
                .animation(.none)
        }
	}
}

#Preview {
    StepWeeklyChart(stepCountGoal: .constant(10000))
        .frame(height: 250)
}
