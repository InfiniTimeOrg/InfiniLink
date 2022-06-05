//
//  HeartChart2.swift
//  InfiniLink
//
//  Created by John Stanley on 5/11/22.
//

import SwiftUI

import SwiftUI
import SwiftUICharts

struct HeartContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 1"))
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    @State var pickerSelection = 0
    @State var numberOfBars : [Int] = [72, 10]
    @State var barSpacing : [CGFloat] = [1, 15]
    @State var barLineNumb : [Int] = [5, 5, 8, 6, 7, 13]
    //@State var barTitles : [String] = ["BATTERY LEVEL", "BATTERY USAGE"]
    @State var barTime : [[String]] =
        [
        ["12 A", "3", "6", "9", "12 P", "3", "6", "9"],
        ["00", "03", "06", "09", "12", "15", "18", "21"]
        ]
    @State var barDate : [String] =
        ["S", "M", "T", "W", "T", "F", "S", "", "", ""]
    @State var monthNames : [String] =
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    @State var barDates : [[String]] =
        [
        [],
        ["12 AM", "6    ", "12 PM", "6    "],
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        [],
        [],
        ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        ]
    
    
    var body: some View {
        
        //let dataPoints = ChartManager.shared.convert(results: chartPoints)
        let clockFormat = DateFormatter.dateFormat (fromTemplate: "j",options:0, locale: Locale.current) == "HH" ? true : false
        let hourTime = Int(Calendar.current.component(.hour, from: Date()))
        let yearDate = Int(Calendar.current.component(.year, from: Date()))
        let monthDate = Int(Calendar.current.component(.month, from: Date()))
        
        ZStack {
            VStack{
                Picker("Stats", selection: $pickerSelection)   {
                    Text("H").tag(0)
                    Text("D").tag(1)
                    Text("W").tag(2)
                    Text("M").tag(3)
                    Text("6M").tag(4)
                    Text("Y").tag(5)
                }
                    .pickerStyle(.segmented)

                Text("RANGE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                HStack(alignment: .bottom) {
                    Text("No Data")
                        .font(.system(size: 24))
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                    
                Divider()
                
                if pickerSelection == 0 {
                    if clockFormat == true {
                        Text("Today, \(hourTime)-\(hourTime + 1)").frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                    } else {
                        Text("Today, \(hourTime - (hourTime > 12 ? 12 : 0))-\((hourTime - (hourTime > 12 ? 12 : 0)) + 1) PM").frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                    }
                } else if pickerSelection == 1 {
                    Text("Today").frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                } else if pickerSelection == 3 {
                    Text("\(monthNames[monthDate - 1]) \(String(yearDate))").frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                } else if pickerSelection == 5 {
                    Text(String(yearDate)).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                } else {
                    Text("No Time").frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 12)).foregroundColor(.gray)
                }
                    
                HStack {
                    GeometryReader { (geometry) in
                        //let bar_width = (Int(geometry.size.width - 2) - (Int(barSpacing[pickerSelection]) * (numberOfBars[pickerSelection] - 1)))
                        VStack {
                            ZStack {
                                verticalLines(numbLines: barLineNumb[pickerSelection], sizes: geometry.size, height: 160)
                                HorizontalLines(numbLines: 5, sizes: geometry.size, height: 160)
                                HStack(alignment: .center) {
                                    //let hour = (Calendar.current.component(.hour, from: Date()) - Int(floor(Double(Calendar.current.component(.hour, from: Date())) / 3.0) * 3.0)) * (numberOfBars[pickerSelection] / 24)
                                    //let minute = Int(ceil(Double(Calendar.current.component(.minute, from: Date())) / (60 / (Double(numberOfBars[pickerSelection]) / 24))))
                                    
                                    //if pickerSelection == 0 {
                                    //    Spacer(minLength: 1)
                                    //    ForEach(1...numberOfBars[pickerSelection], id: \.self) {
                                    //        data in

                                    //        if (data) < (numberOfBars[pickerSelection] + 1) - ((numberOfBars[pickerSelection] / (barLineNumb[pickerSelection] - 1)) - (hour + minute)) {
                                    //            BarView(value: getValue(data_points: dataPoints, timeSinceNow: Double((numberOfBars[pickerSelection] - (Int(data) + ((numberOfBars[pickerSelection] / (barLineNumb[pickerSelection] - 1)) - (hour + minute)))) * (86400 / numberOfBars[pickerSelection]))), cornerRadius: CGFloat(3), width: CGFloat(bar_width / numberOfBars[pickerSelection]), valueHeight:   barValues[pickerSelection].max()!, height: 100)
                                    //        } else {
                                    //            Spacer(minLength: CGFloat(bar_width / numberOfBars[pickerSelection]))
                                    //        }
                                    //        if data != numberOfBars[pickerSelection] {Spacer(minLength: barSpacing[pickerSelection])}
                                    //    }
                                    //    Spacer(minLength: 1)
                                    //} else {
                                    Text("Currently Unavailable")
                                    //}
                                    
                                }
                            }
                           
                        
                            VStack {
                                HStack(alignment: .top) {
                                    if pickerSelection == 0 {
                                        ForEach(1...(barLineNumb[pickerSelection] - 1), id: \.self) { numb in
                                            if clockFormat == true {
                                                Text("\(hourTime):\(numb == 1 ? "00" : String((numb - 1) * 15))")
                                                    .frame(width: 50, alignment: .leading)
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 10))
                                            } else {
                                                Text("\(hourTime - (hourTime > 12 ? 12 : 0)):\(numb == 1 ? "00" : String((numb - 1) * 15)) \(hourTime > 12 ? "PM" : "AM")")
                                                    .frame(width: 50, alignment: .leading)
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 10))
                                            }
                                            Spacer()
                                        }
                                    } else if pickerSelection == 3 {
                                        let monthDays = monthLength(year: yearDate, month: monthDate)
                                        ForEach(1...(barLineNumb[pickerSelection] - 1), id: \.self) { numb in
                                            Text(String(Int((Double(monthDays) / Double(barLineNumb[pickerSelection] - 1)) * Double(numb - 1)) + 1))
                                                .frame(width: 40, alignment: .leading)
                                                .foregroundColor(.gray)
                                                .font(.system(size: 10))
                                            Spacer()
                                        }
                                    } else if pickerSelection == 4 {
                                        ForEach(1...(barLineNumb[pickerSelection] - 1), id: \.self) { numb in
                                            Text(String(monthNames[abs(Int((monthDate + 12) - (barLineNumb[pickerSelection] - numb)) % 12)]))
                                                .foregroundColor(.gray)
                                                .font(.system(size: 10))
                                            Spacer()
                                        }
                                    } else {
                                        ForEach(1...barDates[pickerSelection].count, id: \.self) { numb in
                                            Text(barDates[pickerSelection][numb - 1])
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
                        Text("220")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                        
                        Spacer()
                        
                        Text("125")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                        
                        Spacer()
                        
                        Text("30")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                        
                    }
                        .padding(.bottom, 45)
                }
            }
                .padding(.top, 12)
        }
            .frame(height: 345, alignment: .top)
    }
    
    
    func getValue(data_points: [LineChartDataPoint], timeSinceNow: Double) -> CGFloat {
        for i in 1...data_points.count {
            let value = abs(data_points[data_points.count - i].date!.timeIntervalSinceNow)
            if value > (timeSinceNow - ((60 / (Double(numberOfBars[pickerSelection]) / 24)) * 120)) {
                if value < (timeSinceNow + ((60 / (Double(numberOfBars[pickerSelection]) / 24)) * 540))  {
                    return data_points[data_points.count - i].value
                }
            }
        }
        return 0.0
    }
    
    func monthLength(year: Int, month: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!

        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
}
