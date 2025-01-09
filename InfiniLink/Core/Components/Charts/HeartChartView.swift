//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import SwiftUI
import SwiftUICharts

struct HeartChartView: View {
    @ObservedObject var chartManager = ChartManager.shared
    
    let heartPoints: [HeartDataPoint]
    
    var body: some View {
        let chartStyle = LineChartStyle(infoBoxPlacement: .floating /* TODO: fork and set to infoBox */, infoBoxBackgroundColour: Color(.secondarySystemBackground), baseline: .minimumValue, topLine: .maximumValue)
        let lineStyle = LineStyle(lineColour: ColourStyle(colours: [Color.red.opacity(0.8), Color.red.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineType: .line, ignoreZero: true)
        let data = LineChartData(dataSets: LineDataSet(dataPoints: chartManager.convert(heartPoints), style: lineStyle), chartStyle: chartStyle)
        
        FilledLineChart(chartData: data)
            .floatingInfoBox(chartData: data)
            .touchOverlay(chartData: data, unit: .suffix(of: "BPM"))
            .yAxisLabels(chartData: data)
            .animation(.none)
    }
}
