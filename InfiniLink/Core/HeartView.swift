//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import Accelerate
import CoreData
import Charts

struct HeartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    
    @State private var offset = 0.0
    @State private var selectedDay = ""
    @State private var selectedType = ""
    @State private var selectedHeartRate = 0.0
    @State private var showSelectionBar = false
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    var heartPointValues: [Double] {
        return heartPoints.compactMap({ $0.value })
    }
    
    func setChartSelectionToAvg() {
        offset = 0
        let averageHeartRate = heartPointValues.isEmpty ? 0 : vDSP.mean(heartPointValues)
        selectedHeartRate = averageHeartRate
        selectedType = "Average"
        selectedDay = "Oct 6-13" // TODO: add dynamic date calculation
    }
    func heartRate(for val: Double) -> String {
        return val > 0 ? String(format: "%.0f", val) : "--"
    }
    func units(for seconds: Int) -> String {
        if seconds >= 172800 {
            return NSLocalizedString("Several days ago", comment: "")
        } else if seconds >= 86400 {
            let days = seconds / 86400
            return NSLocalizedString("\(days) day\(days == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 3600 {
            let hours = seconds / 3600
            return NSLocalizedString("\(hours) hour\(hours == 1 ? "" : "s") ago", comment: "")
        } else if seconds >= 60 {
            let minutes = seconds / 60
            return NSLocalizedString("\(minutes) minute\(minutes == 1 ? "" : "s") ago", comment: "")
        }
        return NSLocalizedString("Now", comment: "")
    }
    func timestamp(for heartPoint: HeartDataPoint?) -> String {
        guard let timeInterval = heartPoint?.timestamp?.timeIntervalSinceNow else { return "Unknown" }
        
        if abs(timeInterval) <= 10 {
            return NSLocalizedString("Now", comment: "")
        } else {
            return units(for: Int(abs(timeInterval)))
        }
    }
    func heartRateValuesForSelection() -> [(String, Double)] {
//        let calendar = Calendar.current
//        var data: [(String, Double)] = []
//        let dateFormatter = DateFormatter()
        
        return [
            ("6 AM", 112.0),
            ("6 AM", 111.0),
            ("6 AM", 110.0),
            ("6 AM", 109.0),
            ("6 AM", 108.0),
            ("6 AM", 70.0),
            ("6 AM", 67.0),
            ("12 PM", 76.0),
            ("6 PM", 52.0),
            ("12 AM", 47.0)
        ]
//        switch dataSelection {
//        case 0: // Weekly (last 7 days with day names)
//            dateFormatter.dateFormat = "EEE"
//            for dayOffset in 0..<7 {
//                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
//                    let dayName = dateFormatter.string(from: date)
//                    let stepCount = Int(steps(for: date)) ?? 0
//                    data.insert((dayName, stepCount), at: 0) // Insert to maintain order
//                }
//            }
//        case 1: // Monthly (showing each day of the month, label every 7th day)
//            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) {
//                let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
//                
//                for dayOffset in range {
//                    if let dayDate = calendar.date(byAdding: .day, value: dayOffset - 1, to: startOfMonth) {
//                        let dayNumber = calendar.component(.day, from: dayDate)
//                        let stepCount = Int(steps(for: dayDate)) ?? 0
//                        
//                        let label = (dayOffset % 7 == 0) ? "\(dayNumber)" : "1"
//                        data.append((label, stepCount))
//                    }
//                }
//            }
//        case 2: // Last 6 months
//            for monthOffset in 0..<6 {
//                if let startOfMonth = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
//                    let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
//                    var totalSteps = 0
//                    
//                    // Sum steps for the entire month
//                    for day in range {
//                        if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
//                            totalSteps += Int(steps(for: dayDate)) ?? 0
//                        }
//                    }
//                    
//                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: startOfMonth) - 1)
//                    data.insert((monthName, totalSteps), at: 0)
//                }
//            }
//        case 3: // Year (past 12 months)
//            for monthOffset in 0..<12 {
//                if let startOfMonth = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
//                    let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
//                    var totalSteps = 0
//                    
//                    // Sum steps for the entire month
//                    for day in range {
//                        if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
//                            totalSteps += Int(steps(for: dayDate)) ?? 0
//                        }
//                    }
//                    
//                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: startOfMonth) - 1)
//                    data.insert((monthName, totalSteps), at: 0)
//                }
//            }
//        default:
//            break
//        }
        
//        return data
    }
    
    struct MonthlyHoursOfSunshine: Identifiable {
        var id = UUID()
        var date: Date
        var hoursOfSunshine: Double
        
        
        init(month: Int, hoursOfSunshine: Double) {
            let calendar = Calendar.autoupdatingCurrent
            self.date = calendar.date(from: DateComponents(year: calendar.dateComponents([.year], from: Date()).year ?? 0, month: month))!
            self.hoursOfSunshine = hoursOfSunshine
        }
    }
    
    
    var data: [MonthlyHoursOfSunshine] = [
        MonthlyHoursOfSunshine(month: 1, hoursOfSunshine: 74),
        MonthlyHoursOfSunshine(month: 2, hoursOfSunshine: 89),
        MonthlyHoursOfSunshine(month: 3, hoursOfSunshine: 67),
        MonthlyHoursOfSunshine(month: 4, hoursOfSunshine: 94),
        MonthlyHoursOfSunshine(month: 8, hoursOfSunshine: 45),
        MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Section {
                        DetailHeaderView(Header(title: String(format: "%.0f", bleManager.heartRate == 0 ? heartPointValues.last ?? 0 : bleManager.heartRate), subtitle: heartPoints.isEmpty ? nil : timestamp(for: heartPoints.last), units: "BPM", icon: "heart.fill", accent: .red), width: geo.size.width, animate: true) {
                            HStack {
                                DetailHeaderSubItemView(
                                    title: "Min",
                                    value: heartRate(for: heartPointValues.min() ?? 0)
                                )
                                DetailHeaderSubItemView(
                                    title: "Avg",
                                    value: {
                                        let meanValue = heartPointValues.isEmpty ? 0 : vDSP.mean(heartPointValues)
                                        return heartRate(for: Double(meanValue))
                                    }()
                                )
                                DetailHeaderSubItemView(
                                    title: "Max",
                                    value: heartRate(for: heartPointValues.max() ?? 0)
                                )
                            }
                        }
                    }
                    Section {
                        Picker("Range", selection: $dataSelection) {
                            ForEach(0...5, id: \.self) { index in
                                Text({
                                    switch index {
                                    case 0: return "H"
                                    case 1: return "D"
                                    case 2: return "W"
                                    case 3: return "M"
                                    case 4: return "6M"
                                    case 5: return "Y"
                                    default: return "-"
                                    }
                                }())
                                .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    VStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedType.uppercased())
                                .foregroundColor(Color(.darkGray))
                                .font(.caption.weight(.semibold))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(String(format: "%.0f", selectedHeartRate)) BPM")
                                    .font(.title3.weight(.bold))
                                Text(selectedDay)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.leading, 10)
                        .frame(width: 150, height: 76, alignment: .leading)
                        .background(Material.regular)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(x: offset)
                        .frame(maxWidth: .infinity, alignment: .leading)
//                        Chart(data) {
//                            LineMark(
//                                x: .value("Month", $0.date),
//                                y: .value("Hours of Sunshine", $0.hoursOfSunshine)
//                            )
//                            .foregroundStyle(.red)
//                        }
//                        .frame(height: geo.size.width / 1.8)
//                        Chart {
//                            ForEach(heartRateValuesForSelection(), id: \.0) { (label, rate) in
//                                PointMark(
//                                    x: .value("Label", label),
//                                    y: .value("Range", rate)
//                                )
//                                .foregroundStyle(Color.red)
//                            }
//                        }
//                        .chartOverlay { overlayProxy in
//                            GeometryReader { geoProxy in
//                                Rectangle()
//                                    .foregroundStyle(Material.regular)
//                                    .frame(width: 3, height: geoProxy.size.height * 0.95)
//                                    .offset(x: offset)
//                                    .opacity(showSelectionBar ? 1 : 0)
//                                Rectangle().fill(.clear).contentShape(Rectangle())
//                                    .gesture(DragGesture()
//                                        .onChanged { value in
//                                            if !showSelectionBar {
//                                                showSelectionBar = true
//                                            }
//                                            
//                                            let minX = geoProxy[overlayProxy.plotAreaFrame].minX
//                                            let maxX = geoProxy[overlayProxy.plotAreaFrame].maxX
//                                            let origin = geoProxy[overlayProxy.plotAreaFrame].origin
//                                            let location = CGPoint(x: value.location.x - origin.x, y: 0)
//                                            
//                                            offset = min(max(location.x, minX), maxX)
//                                            
//                                            if let (day, heartVal) = overlayProxy.value(at: location, as: (String, Double).self) {
//                                                selectedType = "Range"
//                                                selectedDay = day
//                                                selectedHeartRate = heartVal
//                                            }
//                                        }
//                                        .onEnded { _ in
//                                            showSelectionBar = false
//                                            setChartSelectionToAvg()
//                                        }
//                                    )
//                            }
//                        }
//                        .frame(height: geo.size.width / 1.8)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Heart Rate")
        .toolbar {
            NavigationLink {
                HeartSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            setChartSelectionToAvg()
        }
    }
}

#Preview {
    NavigationView {
        HeartView()
            .onAppear {
                BLEManager.shared.heartRate = 76
            }
            .navigationBarTitleDisplayMode(.inline)
    }
}
