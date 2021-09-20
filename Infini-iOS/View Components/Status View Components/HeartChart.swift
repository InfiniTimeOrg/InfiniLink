//
//  File.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/18/21.
//  
//


import Foundation
import SwiftUI
import SwiftUICharts

struct HeartChart: View {
	@EnvironmentObject var bleManager: BLEManager
	@AppStorage("heartChartFill") var heartChartFill: Bool = true
	@Environment(\.managedObjectContext) var viewContext
	@Environment(\.colorScheme) var colorScheme
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	func setLineStyle() -> LineStyle {
		if heartChartFill {
			return LineStyle(lineColour: ColourStyle(colours: [Color.red.opacity(0.7), Color.red.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineType: .curvedLine, ignoreZero: false)
		} else {
			return LineStyle(lineColour: ColourStyle(colour: Color.red), lineType: .curvedLine, ignoreZero: false)
		}
	}

	
	var body: some View {
		let chartStyle = LineChartStyle(infoBoxPlacement: .floating, /*infoBoxBackgroundColour: (colorScheme == .dark ? Color.gray : Color.lightGray), */baseline: .minimumWithMaximum(of: 50), topLine: .maximum(of: 160))
		let data = LineChartData(dataSets: LineDataSet(
			dataPoints: ChartManager.shared.convert(results: chartPoints, chart: ChartsAsInts.heart.rawValue),
			style: setLineStyle()),
			chartStyle: chartStyle
		)
		if chartPoints.count > 1 {
			if heartChartFill {
				FilledLineChart(chartData: data)
					.animation(.easeIn)
					.floatingInfoBox(chartData: data)
					.touchOverlay(chartData: data, unit: .suffix(of: "BPM"))
					.yAxisLabels(chartData: data)
					.padding()
				
			} else {
				LineChart(chartData: data)
					.animation(.easeIn)
					.floatingInfoBox(chartData: data)
					.touchOverlay(chartData: data, unit: .suffix(of: "BPM"))
					.yAxisLabels(chartData: data)
					.padding()
			}
		} else {
			VStack (alignment: .center) {
				Spacer()
				HStack (alignment: .center) {
					Text("Insufficient Heart Rate Data")
						.font(.title)
				}
				Spacer()
			}
		}
	}
}
