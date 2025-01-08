//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import SwiftUICharts

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @AppStorage("stepsChartDataSelection") private var dataSelection = 0
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var stepCounts: FetchedResults<StepCounts>
    
    let exerciseCalculator = FitnessCalculator.shared
    
    func getStepCounts(displayWeek: Date) -> [BarChartDataPoint] {
        var dataPoints = [BarChartDataPoint]()
        var calendar = Calendar.autoupdatingCurrent
        var week = displayWeek
        
        calendar.firstWeekday = 1
        week = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        
        for weekDay in 0...6 {
            if let day = calendar.date(byAdding: .day, value: weekDay, to: week) {
                let shortFormatter = DateFormatter()
                shortFormatter.dateFormat = "EEEEE"
                
                let longFormatter = DateFormatter()
                longFormatter.dateFormat = "EEEE"
                
                let color = ColourStyle(colour: .blue)
                dataPoints.append(BarChartDataPoint(value: 0, xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: day, colour: color))
                
                for i in stepCounts {
                    if calendar.isDate(i.timestamp!, inSameDayAs: day) {
                        dataPoints[weekDay] = BarChartDataPoint(value: Double(i.steps), xAxisLabel: shortFormatter.string(from: day), description: longFormatter.string(from: day), date: i.timestamp!, colour: color)
                    }
                }
            }
        }
        
        return dataPoints
    }
    func steps(for date: Date) -> String {
        for stepCount in stepCounts {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
                let formattedSteps = NumberFormatter.localizedString(from: NSNumber(value: stepCount.steps), number: .decimal)
                return formattedSteps
            }
        }
        return "0"
    }
    func chartData() -> BarChartData {
        let metadata   = ChartMetadata(title: "Steps This Week")
        let gridStyle  = GridStyle(numberOfLines: 5,
                                   lineColour: Color(.lightGray).opacity(0.25),
                                   lineWidth: 1)
        let chartStyle = BarChartStyle(infoBoxPlacement: .floating,
                                       markerType: .none,
                                       xAxisGridStyle: gridStyle,
                                       xAxisLabelPosition: .bottom,
                                       xAxisLabelsFrom: .dataPoint(rotation: .degrees(-90)),
                                       yAxisGridStyle: gridStyle,
                                       yAxisLabelPosition: .leading,
                                       yAxisNumberOfLabels: 5,
                                       baseline: .zero,
                                       topLine: .maximum(of: Double(deviceManager.settings.stepsGoal)))
        
        return BarChartData(dataSets: BarDataSet(dataPoints: getStepCounts(displayWeek: Date())),
                            metadata: metadata,
                            barStyle: BarStyle(barWidth: 0.6,
                                                 cornerRadius: CornerRadius(top: 0, bottom: 0),
                                                 colourFrom: .dataPoints,
                                                 colour: ColourStyle(colour: .blue)),
                            chartStyle: chartStyle)
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Section {
                        DetailHeaderView(Header(title: steps(for: Date()), subtitle: String(deviceManager.settings.stepsGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
                            HStack {
                                DetailHeaderSubItemView(title: "Dis",
                                                        value: String(format: "%.2f",
                                                                      exerciseCalculator.metersToMiles(meters: exerciseCalculator.calculateDistance(steps: bleManager.stepCount))),
                                                        unit: "mi")
                                DetailHeaderSubItemView(title: "Kcal", value: String(format: "%.1f", exerciseCalculator.calculateCaloriesBurned(steps: bleManager.stepCount)))
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        Picker("Range", selection: $dataSelection) {
                            Text("W").tag(0)
                            Text("M").tag(1)
                            Text("6M").tag(2)
                            Text("Y").tag(3)
                        }
                        .pickerStyle(.segmented)
                    }
                    Section {
                        BarChart(chartData: chartData())
                            .floatingInfoBox(chartData: chartData())
                            .touchOverlay(chartData: chartData())
                            .xAxisLabels(chartData: chartData())
                            .yAxisLabels(chartData: chartData())
                            .animation(.none)
                            .frame(minHeight: geo.size.width / 1.6)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
        }
        .navigationTitle("Steps")
    }
}

#Preview {
    StepsView()
}
