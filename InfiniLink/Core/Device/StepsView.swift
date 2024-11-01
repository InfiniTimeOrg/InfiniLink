//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import Charts

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @AppStorage("stepsChartDataSelection") private var dataSelection = 0
    
    @State private var offset = 0.0
    @State private var selectedDay = ""
    @State private var selectionType = ""
    @State private var selectedSteps = 0
    @State private var showSelectionBar = false
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
    let exerciseCalculator = FitnessCalculator.shared
    
    func steps(for date: Date) -> String {
        for stepCount in existingStepCounts {
            if Calendar.current.isDate(stepCount.timestamp!, inSameDayAs: date) {
                let formattedSteps = NumberFormatter.localizedString(from: NSNumber(value: stepCount.steps), number: .decimal)
                return formattedSteps
            }
        }
        return "0"
    }
    
    func stepsForSelection() -> [(String, Int)] {
        let calendar = Calendar.current
        var data: [(String, Int)] = []
        let dateFormatter = DateFormatter()
        
        switch dataSelection {
        case 0: // Weekly (last 7 days with day names)
            dateFormatter.dateFormat = "EEE"
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                    let dayName = dateFormatter.string(from: date)
                    let stepCount = Int(steps(for: date)) ?? 0
                    data.insert((dayName, stepCount), at: 0) // Use insert to maintain order
                }
            }
        case 1: // Monthly (showing each day of the month, label every 7th day)
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) {
                let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                
                for dayOffset in range {
                    if let dayDate = calendar.date(byAdding: .day, value: dayOffset - 1, to: startOfMonth) {
                        let dayNumber = calendar.component(.day, from: dayDate)
                        let stepCount = Int(steps(for: dayDate)) ?? 0
                        
                        data.append(("\(dayNumber)", stepCount))
                    }
                }
            }
        case 2: // Last 6 months
            for monthOffset in 0..<6 {
                if let startOfMonth = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
                    let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                    var totalSteps = 0
                    
                    // Sum steps for the entire month
                    for day in range {
                        if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                            totalSteps += Int(steps(for: dayDate)) ?? 0
                        }
                    }
                    
                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: startOfMonth) - 1)
                    data.insert((monthName, totalSteps), at: 0)
                }
            }
        case 3: // Year (past 12 months)
            for monthOffset in 0..<12 {
                if let startOfMonth = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
                    let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                    var totalSteps = 0
                    
                    // Sum steps for the entire month
                    for day in range {
                        if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                            totalSteps += Int(steps(for: dayDate)) ?? 0
                        }
                    }
                    
                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: startOfMonth) - 1)
                    data.insert((monthName, totalSteps), at: 0)
                }
            }
        default:
            break
        }
        
        return data
    }
    
    func setChartSelectionToAvg() {
        let averageSteps = stepsForSelection().map(\.1).reduce(0, +) / stepsForSelection().count
        offset = 0
        selectedSteps = averageSteps // TODO: calculate based on selection
        selectionType = "Average"
        selectedDay = "Oct 6-13" // TODO: add dynamic date
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
                            Text("W").tag(0)  // Weekly
                            Text("M").tag(1)  // Monthly
                            Text("6M").tag(2) // 6 Months
                            Text("Y").tag(3)  // Yearly
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: dataSelection) { _ in setChartSelectionToAvg() }
                    }
                    Section {
                        VStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectionType.uppercased())
                                    .foregroundColor(Color(.darkGray))
                                    .font(.caption.weight(.semibold))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(selectedSteps) steps")
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
                            Chart {
                                ForEach(stepsForSelection(), id: \.0) { (label, stepCount) in
                                    BarMark(
                                        x: .value("Label", label),
                                        y: .value("Steps", stepCount)
                                    )
                                }
                            }
                            .chartOverlay { overlayProxy in
                                GeometryReader { geoProxy in
                                    Rectangle()
                                        .foregroundStyle(Material.regular)
                                        .frame(width: 3, height: geoProxy.size.height * 0.95)
                                        .offset(x: offset)
                                        .opacity(showSelectionBar ? 1 : 0)
                                    Rectangle().fill(.clear).contentShape(Rectangle())
                                        .gesture(DragGesture()
                                            .onChanged { value in
                                                if !showSelectionBar {
                                                    showSelectionBar = true
                                                }
                                                
                                                let minX = geoProxy[overlayProxy.plotAreaFrame].minX
                                                let maxX = geoProxy[overlayProxy.plotAreaFrame].maxX
                                                let origin = geoProxy[overlayProxy.plotAreaFrame].origin
                                                let location = CGPoint(x: value.location.x - origin.x, y: 0)
                                                
                                                offset = min(max(location.x, minX), maxX)
                                                
                                                if let (day, steps) = overlayProxy.value(at: location, as: (String, Int).self) {
                                                    selectionType = "Total"
                                                    selectedDay = day
                                                    selectedSteps = steps
                                                }
                                            }
                                            .onEnded { _ in
                                                showSelectionBar = false
                                                setChartSelectionToAvg()
                                            }
                                        )
                                }
                            }
                            .frame(height: geo.size.width / 1.8)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Steps")
        .onAppear {
            setChartSelectionToAvg()
        }
    }
}

#Preview {
    StepsView()
}
