//
//  File.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/18/21.
//
//
	

import Foundation
import SwiftUI
import SwiftUICharts

struct BatteryChart: View {
	@ObservedObject var bleManager = BLEManager.shared
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
	
	func setGraphType(data: LineChartData) -> some View {
		if batChartFill {
			return AnyView(FilledLineChart(chartData: data))
		} else {
			return AnyView(LineChart(chartData: data))
		}
	}
	
	var body: some View {
		let dataPoints = ChartManager.shared.convert(results: chartPoints)
		let chartStyle = LineChartStyle(infoBoxPlacement: .floating, baseline: .minimumWithMaximum(of: 0), topLine: .maximum(of: 100))
		let data = LineChartData(dataSets: LineDataSet(
			dataPoints: dataPoints,
			style: setLineStyle()),
			chartStyle: chartStyle
		)
		
		if dataPoints.count > 1 {
			setGraphType(data: data)
				.animation(.easeIn)
				.floatingInfoBox(chartData: data)
				.touchOverlay(chartData: data, unit: .suffix(of: "%"))
				.yAxisLabels(chartData: data)
				.padding()
		} else {
			VStack (alignment: .center) {
				Spacer()
				HStack (alignment: .center) {
					Text(NSLocalizedString("insufficient_battery_data", comment: ""))
						.font(.title)
				}
				Spacer()
			}
		}
	}
}
