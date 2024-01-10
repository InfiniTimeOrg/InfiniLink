//
//  BatteryChart.swift
//  InfiniLink
//
//  Created by John Stanley on 5/6/22.
//

import SwiftUI
import SwiftUICharts

struct BatteryContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
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
    
    @State var barValues : [[CGFloat]] =
    [
        [100,100,100,97,96,95,93,93,92,90,89,89,88,87,86,84,83,83,82,81,80,77,77,76,75,74,73,72,71,70,68,68,68,64,63,62,60,59,58,57,55,55,55,54,52,50,47,44],
        [5,150,50,100,200,110,30,170,50,100]
    ]
    
    
    var body: some View {
        
        let dataPoints = ChartManager.shared.convert(results: chartPoints)
        let clockFormat = DateFormatter.dateFormat (fromTemplate: "j",options:0, locale: Locale.current) == "HH" ? 1 : 0
        
        ZStack {
            VStack {
                Text(barTitles[pickerSelection]).frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                HStack {
                    GeometryReader { (geometry) in
                        let barWidth = (Int(geometry.size.width - 2) - (Int(barSpacing[pickerSelection]) * (numberOfBars[pickerSelection] - 1)))
                        VStack {
                            ZStack {
                                verticalLines(numbLines: barLineNumb[pickerSelection], sizes: geometry.size, height: 100)
                                HorizontalLines(numbLines: 5, sizes: geometry.size, height: 100)
                                
                                HStack(alignment: .center) {
                                    let hour = (Calendar.current.component(.hour, from: Date()) - Int(floor(Double(Calendar.current.component(.hour, from: Date())) / 3.0) * 3.0)) * (numberOfBars[pickerSelection] / 24)
                                    let minute = Int(ceil(Double(Calendar.current.component(.minute, from: Date())) / (60 / (Double(numberOfBars[pickerSelection]) / 24))))
                                    
                                    if pickerSelection == 0 {
                                        Spacer(minLength: 1)
                                        ForEach(1...numberOfBars[pickerSelection], id: \.self) { data in
                                            if (data) < (numberOfBars[pickerSelection] + 1) - ((numberOfBars[pickerSelection] / (barLineNumb[pickerSelection] - 1)) - (hour + minute)) {
                                                BarView(value: getValue(data_points: dataPoints, timeSinceNow: Double((numberOfBars[pickerSelection] - (Int(data) + ((numberOfBars[pickerSelection] / (barLineNumb[pickerSelection] - 1)) - (hour + minute)))) * (86400 / numberOfBars[pickerSelection]))), cornerRadius: CGFloat(3), width: CGFloat(barWidth / numberOfBars[pickerSelection]), valueHeight: barValues[pickerSelection].max()!, height: 100)
                                            } else {
                                                Spacer(minLength: CGFloat(barWidth / numberOfBars[pickerSelection]))
                                            }
                                            if data != numberOfBars[pickerSelection] { Spacer(minLength: barSpacing[pickerSelection]) }
                                        }
                                        Spacer(minLength: 1)
                                    } else {
                                        Text(NSLocalizedString("currently_unavailable", comment: ""))
                                    }
                                }
                            }
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
                        Spacer()
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
                    .padding(.bottom, 30)
                }
            }
        }
        .frame(maxHeight: 250, alignment: .top)
    }
    
    
    func getValue(data_points: [LineChartDataPoint], timeSinceNow: Double) -> CGFloat {
        let connectedDataPoints = ChartManager.shared.convert(results: connectedChartPoints)
        if data_points.count == 0 {return 0.0}
        
        for i in 1...data_points.count {
            let value = abs(data_points[data_points.count - i].date!.timeIntervalSinceNow)
            if value > timeSinceNow {
                let valueOne = data_points[data_points.count - i].value
                let valueTwo = (i - 1) > 0 ? data_points[data_points.count - (i - 1)].value : valueOne
                
                let timeTwo = (i - 1) > 0 ? abs(data_points[data_points.count - (i - 1)].date!.timeIntervalSinceNow) : value
                
                let interpolationValue = (timeSinceNow - timeTwo) / (value - timeTwo)
                
                if isConnected(data_points: connectedDataPoints, timeSinceNow: interpolation(interpolation: interpolationValue, xValue: value, yValue: timeTwo)) {
                    if String(abs(interpolationValue)) != "inf" {
                        return round(interpolation(interpolation: interpolationValue, xValue: valueOne, yValue: valueTwo))
                    } else {
                        return round(valueOne)
                    }
                } else {
                    return 0.0
                }
            }
        }
        return 0.0
    }
    
    func isConnected(data_points: [LineChartDataPoint], timeSinceNow: Double) -> Bool {
        for i in 1...data_points.count {
            let value = abs(data_points[data_points.count - i].date!.timeIntervalSinceNow)
            if String(timeSinceNow) == "nan" || value > timeSinceNow {
                if data_points[data_points.count - i].value == 0 {
                    return false
                } else {
                    return true
                }
            }
        }
        return true
    }
    
    func interpolation(interpolation: Double, xValue: Double, yValue: Double) -> Double {
        return(yValue * (1 - interpolation) + xValue * interpolation)
    }
}
