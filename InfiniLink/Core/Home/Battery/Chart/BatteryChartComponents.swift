//
//  BatteryChart.swift
//  InfiniLink
//
//  Created by John Stanley on 5/6/22.
//

import SwiftUI
import SwiftUICharts

struct BatteryContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 1"))
    private var chartPoints: FetchedResults<ChartDataPoint>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 2"))
    private var connectedChartPoints: FetchedResults<ChartDataPoint>

    @State var pickerSelection = 0
    @State var numberOfBars : [Int] = [72, 10]
    @State var barSpacing : [CGFloat] = [1, 15]
    @State var barLineNumb : [Int] = [9, 11]
    @State var barTitles : [String] = [NSLocalizedString("battery_level", comment: ""), NSLocalizedString("battery_usage", comment: "")]
    @State var barTime : [[String]] =
    [
        ["12 A", "3", "6", "9", "12 P", "3", "6", "9"],
        ["00", "03", "06", "09", "12", "15", "18", "21"]
    ]
    @State var barDate : [String] =
    ["S", "M", "T", "W", "T", "F", "S", "", "", ""]
        
    
    func setBarStyle() -> BarStyle {
        return BarStyle(barWidth: 0.75, cornerRadius: CornerRadius(top: 50, bottom: 0), colourFrom: .dataPoints)
    }

    func setGraphType(data: BarChartData) -> some View {
        return AnyView(BarChart(chartData: data))
    }

    var body: some View {
        let clockFormat = DateFormatter.dateFormat (fromTemplate: "j",options:0, locale: Locale.current) == "HH" ? 1 : 0
        
        let chartStyle = BarChartStyle(baseline: .minimumWithMaximum(of: 100), topLine: .maximum(of: 100), globalAnimation: .linear(duration: 0))
        let data = BarChartData(dataSets: BarDataSet(dataPoints: ChartManager.shared.convertBat(results: chartPoints, connected: connectedChartPoints)), barStyle: setBarStyle(), chartStyle: chartStyle)

        
        ZStack {
            VStack {
                Text(barTitles[pickerSelection]).frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                HStack {
                    GeometryReader { (geometry) in
                        VStack {
                            ZStack {
                                // TODO: Fix lag due to these indicator lines without removing them
//                                VerticalLines(numbLines: barLineNumb[pickerSelection], sizes: geometry.size, height: 100)
//                                HorizontalLines(numbLines: 5, sizes: geometry.size, height: 100)
                                VStack {
                                    Divider()
                                    Spacer()
                                    Divider()
                                    Spacer()
                                    Spacer()
                                        .frame(height: 5)
                                }
                                VStack {
                                    setGraphType(data: data)
                                        .animation(nil)
                                        .id(data.id)
                                    Spacer(minLength: 10)
                                }
                            }
                            .frame(maxHeight: 110)
                            .frame(minHeight: 110, alignment: .top)
                            VStack {
                                HStack(alignment: .top) {
                                    if pickerSelection == 0 {
                                        ForEach(1...barTime[clockFormat].count, id: \.self) { numb in
                                            Text(barTime[clockFormat][(Int(floor(Double(Calendar.current.component(.hour, from: Date())) / 3.0)) + numb) % barTime[clockFormat].count])
                                                .foregroundColor(.gray)
                                                .font(.system(size: 10))

                                            Spacer()
                                        }
                                    } else {
                                        ForEach(1...barDate.count, id: \.self) { numb in
                                            let testing = ((Calendar.current.component(.weekday, from: Date()) + 13) - (barDate.count - numb)) % 7
                                            Text(barDate[abs(testing)])
                                                .foregroundColor(.gray)
                                                .font(.system(size: 10))

                                            Spacer()
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Blank")
                            .opacity(0.0)
                        Text("100%")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                        Spacer()
                        Text("50%")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                        Spacer()
                        Text("0%")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                    }
                    .padding(.top, -20)
                    .padding(.bottom, 32)
                }
            }
            .frame(maxHeight: 160, alignment: .top)
        }
        .frame(maxHeight: 250, alignment: .top)
    }
    
    func interpolation(interpolation: Double, xValue: Double, yValue: Double) -> Double {
        return(yValue * (1 - interpolation) + xValue * interpolation)
    }
}
#Preview {
    BatteryView()
}
