//
//  BatteryChart.swift
//  InfiniLink
//
//  Created by John Stanley on 5/6/22.
//

import SwiftUI

struct BatteryContentView: View {
    //@Environment(\.colorScheme) var colorScheme
    @ObservedObject var bleManager = BLEManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 1"))
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    @State var pickerSelection = 0
    @State var barSpacing : [CGFloat] = [1, 15]
    @State var barLineNumb : [Int] = [8, 11]
    @State var barTitles : [String] = ["BATTERY LEVEL", "BATTERY USAGE"]
    @State var barTime : [[String]] =
        [
        ["12 P", "4", "8", "12 A", "4", "8"],
        ["M", "T", "S", "M", "T", "W", "T", "F", "S", "S"],
        ]
    
    @State var barValues : [[CGFloat]] =
        [
        [100,100,100,97,96,95,93,93,92,90,89,89,88,87,86,84,83,83,82,81,80,77,77,76,75,74,73,72,71,70,68,68,68,64,63,62,60,59,58,57,55,55,55,54,52,50,47,44],
        [5,150,50,100,200,110,30,170,50,100]
        ]
    
    var body: some View {
        let dataPoints = ChartManager.shared.convert(results: chartPoints)
        
        ZStack {
            VStack{
                Picker("Stats", selection: $pickerSelection)   {
                    Text("Last 24 Hours").tag(0)
                    Text("Last 10 Days").tag(1)
                }
                    .pickerStyle(.segmented)
                    //.pickerStyle(SegmentedPickerStyle())
                    //.

                
                Text("Battery Level is \(Int(bleManager.batteryLevel))%").frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16))
                    
                Divider()
                    
                Text(barTitles[pickerSelection]).frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    
                HStack {
                    GeometryReader { (geometry) in
                        let bar_width = (Int(geometry.size.width) - (Int(barSpacing[pickerSelection]) * barValues[pickerSelection].count))
                        VStack {
                            ZStack {
                                verticalLines(numbLines: barLineNumb[pickerSelection], sizes: geometry.size)
                                HorizontalLines(numbLines: 5, sizes: geometry.size)
                                    
                                HStack(alignment: .center, spacing: barSpacing[pickerSelection]) {
                                    ForEach(barValues[pickerSelection], id: \.self) {
                                        data in
                    
                                        BarView(value: data, cornerRadius: CGFloat(3), width: CGFloat(bar_width / barValues[pickerSelection].count), valueHeight:   barValues[pickerSelection].max()!, height: 100)
                                    }
                                }
                            }
                                
                            VStack {
                                HStack(alignment: .top) {
                                    ForEach(1...barTime[pickerSelection].count, id: \.self) { numb in
                                        Text(barTime[pickerSelection][numb - 1])
                                            .foregroundColor(.gray)
                                            .font(.system(size: 12))
                                        Spacer()
                                    }
                                    
                                }
                                Spacer()
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("100%")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Text("50%")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                        
                        Spacer()
                        
                        Text("0%")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                        
                    }
                        .padding(.bottom, 40)
                }
            }
                .padding(.top, 12)
        }
            .frame(height: 265, alignment: .top)
    }
}

struct BarView: View {

    var value: CGFloat
    var cornerRadius: CGFloat
    var width: CGFloat
    var valueHeight: CGFloat
    var height: CGFloat
    
    var body: some View {
        VStack {
            ZStack (alignment: .bottom) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: width, height: height).foregroundColor(.clear)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: width, height: value * (height / valueHeight)).foregroundColor(.green)
                RoundedRectangle(cornerRadius: 0)
                    .frame(width: width, height: (value * (height / valueHeight)) / 2).foregroundColor(.green)
                
            }
            Spacer()
        }
        
    }
}

struct HorizontalLines: View {
    var numbLines: Int
    var sizes: CGSize
    
    var body: some View {
        VStack(alignment: .center) {
            ForEach((1...numbLines).reversed(), id: \.self) {numb in
                RoundedRectangle(cornerRadius: 0)
                    .frame(width: sizes.width, height: 1).foregroundColor(Color(light: .lightGray, dark: .darkGray))
                if numb != 1 {
                    Spacer(minLength: (100 - CGFloat(numbLines)) / CGFloat(numbLines - 1))
                }
            }
            Spacer()
        }
    }
}

struct verticalLines: View {
    var numbLines: Int
    var sizes: CGSize
    
    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                ForEach((1...numbLines).reversed(), id: \.self) {numb in
                    RoundedRectangle(cornerRadius: 0)
                        .frame(width: 1, height: 100).foregroundColor(Color(light: .lightGray, dark: .darkGray))
                    if numb != 1 {
                        Spacer(minLength: (sizes.width - CGFloat(numbLines)) / CGFloat(numbLines - 1))
                    }
                }
            }
            Spacer()
        }
    }
}

extension UIColor {
  convenience init(light: UIColor, dark: UIColor) {
    self.init { traitCollection in
      switch traitCollection.userInterfaceStyle {
      case .light, .unspecified:
        return light
      case .dark:
        return dark
      @unknown default:
        return light
      }
    }
  }
}

extension Color {
  init(light: Color, dark: Color) {
    self.init(UIColor(light: UIColor(light), dark: UIColor(dark)))
  }
}
