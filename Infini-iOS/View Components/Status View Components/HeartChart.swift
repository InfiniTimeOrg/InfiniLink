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

struct HeartChart: View {
	@EnvironmentObject var bleManager: BLEManager

	let lineStyle = LineStyle(lineColour: ColourStyle(colours: [Color.red.opacity(0.7), Color.red.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineType: .curvedLine, ignoreZero: false)
	
	
	var body: some View {
		let chartStyle = LineChartStyle(infoBoxPlacement: .floating, baseline: .minimumWithMaximum(of: 50), topLine: .maximum(of: 160))
		let data = LineChartData(dataSets: LineDataSet(
										dataPoints: bleManager.hrmChartDataPoints,
										style: lineStyle),
									chartStyle: chartStyle
								 )
		if bleManager.hrmChartDataPoints.count > 1 {
			FilledLineChart(chartData: data)
				.animation(.easeIn)
				.floatingInfoBox(chartData: data)
				.touchOverlay(chartData: data, unit: .suffix(of: "BPM"))
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
