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

struct BatteryChart: View {
	@EnvironmentObject var bleManager: BLEManager
	@AppStorage("batChartFill") var batChartFill: Bool = true
	@Environment(\.managedObjectContext) var viewContext
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 1"))
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	func setLineStyle() -> LineStyle {
		if batChartFill {
			return LineStyle(lineColour: ColourStyle(colours: [Color.green.opacity(0.7), Color.green.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineType: .curvedLine, ignoreZero: false)
		} else {
			return LineStyle(lineColour: ColourStyle(colour: Color.green), lineType: .curvedLine, ignoreZero: false)
		}
	}
	
	
	var body: some View {
		let chartStyle = LineChartStyle(infoBoxPlacement: .floating, baseline: .minimumWithMaximum(of: 0), topLine: .maximum(of: 100))
		let data = LineChartData(dataSets: LineDataSet(
			dataPoints: ChartManager.shared.convert(results: chartPoints),
			style: setLineStyle()),
			chartStyle: chartStyle
		)
		
		if chartPoints.count > 1 {
			if batChartFill {
				FilledLineChart(chartData: data)
					.animation(.easeIn)
					.floatingInfoBox(chartData: data)
					.touchOverlay(chartData: data, unit: .suffix(of: "%"))
					.yAxisLabels(chartData: data)
					.padding()
			} else {
				LineChart(chartData: data)
					.animation(.easeIn)
					.floatingInfoBox(chartData: data)
					.touchOverlay(chartData: data, unit: .suffix(of: "%"))
					.yAxisLabels(chartData: data)
					.padding()
			}
		} else {
			VStack (alignment: .center) {
				Spacer()
				HStack (alignment: .center) {
					Text("Insufficient Battery Data")
						.font(.title)
				}
				Spacer()
			}
		}
	}
}
