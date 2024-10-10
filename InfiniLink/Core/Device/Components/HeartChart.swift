//
//  HeartChart.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import SwiftUI
import SwiftUICharts
import CoreData

struct HeartChart: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \HeartDataPoint.timestamp, ascending: true)])
    private var heartPoints: FetchedResults<HeartDataPoint>
    
    
    func setLineStyle() -> LineStyle {
        LineStyle(lineColour: ColourStyle(colours: [Color.red.opacity(0.7), Color.red.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineType: .curvedLine, ignoreZero: false)
    }
    
    func setGraphType(data: LineChartData) -> some View {
        FilledLineChart(chartData: data)
    }
    
    var body: some View {
        let dataPoints = ChartManager.shared.convertHeartPointsToChartPoints(points: heartPoints)
        let chartStyle = LineChartStyle(infoBoxPlacement: .floating, baseline: .minimumWithMaximum(of: 50), topLine: .maximum(of: 160))
        let data = LineChartData(dataSets: LineDataSet(dataPoints: dataPoints, style: setLineStyle()), chartStyle: chartStyle)
        
        setGraphType(data: data)
            .floatingInfoBox(chartData: data)
            .touchOverlay(chartData: data, unit: .suffix(of: "BPM"))
            .yAxisLabels(chartData: data)
            .padding(.top, 4)
    }
}

#Preview {
    HeartChart()
}
