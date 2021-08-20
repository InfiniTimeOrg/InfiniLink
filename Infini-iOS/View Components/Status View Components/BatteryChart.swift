//
//  File.swift
//  Infini-iOS
//
//  Created by xan-m on 8/18/21.
//
//
	

import Foundation
import SwiftUI
import SwiftUICharts

struct BatteryChart: View {
	@EnvironmentObject var bleManager: BLEManager

	let lineStyle = LineStyle(lineColour: ColourStyle(colours: [Color.green.opacity(0.7), Color.green.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineType: .curvedLine, ignoreZero: false)
	
	
	var body: some View {
		let chartStyle = LineChartStyle(infoBoxPlacement: .floating, baseline: .minimumWithMaximum(of: 0), topLine: .maximum(of: 100))
		let data = LineChartData(dataSets: LineDataSet(
										dataPoints: bleManager.batChartDataPoints,
										style: lineStyle),
									chartStyle: chartStyle
								 )
		
		if bleManager.batChartDataPoints.count > 1 {
			FilledLineChart(chartData: data)
				.animation(.easeIn)
				.floatingInfoBox(chartData: data)
				.touchOverlay(chartData: data, unit: .suffix(of: "%"))
				.yAxisLabels(chartData: data)
		} else {
			VStack (alignment: .center) {
				Spacer()
				HStack (alignment: .center) {
					Text("Waiting for Data")
						.font(.title)
				}
				Spacer()
			}
		}
	}
}

