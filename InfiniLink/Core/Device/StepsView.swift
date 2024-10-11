//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import Charts

import SwiftUI
import Charts

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @AppStorage("stepsChartDataSelection") private var dataSelection = 0
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var existingStepCounts: FetchedResults<StepCounts>
    
    let exerciseCalculator = FitnessCalculator()
    
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
            dateFormatter.dateFormat = "EEE" // Short weekday name (Mon, Tue, etc.)
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                    let dayName = dateFormatter.string(from: date) // Get the day name
                    let stepCount = Int(steps(for: date)) ?? 0
                    data.insert((dayName, stepCount), at: 0) // Insert to maintain order
                }
            }
            
        case 1: // Monthly (showing each day of the month, label every 7th day)
            if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) {
                let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
                
                for dayOffset in range {
                    if let dayDate = calendar.date(byAdding: .day, value: dayOffset - 1, to: startOfMonth) {
                        let dayNumber = calendar.component(.day, from: dayDate)
                        let stepCount = Int(steps(for: dayDate)) ?? 0
                        
                        let label = (dayOffset % 7 == 0) ? "\(dayNumber)" : "1"
                        data.append((label, stepCount))
                    }
                }
            }
            
        case 2: // Last 6 months
            for monthOffset in 0..<6 {
                if let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: monthDate) - 1)
                    let stepCount = Int(steps(for: monthDate)) ?? 0
                    
                    data.insert((monthName, stepCount), at: 0)
                }
            }
            
        case 3: // Year (past 12 months)
            for monthOffset in 0..<12 {
                if let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) {
                    let monthName = Date.monthAbbreviationFromInt(calendar.component(.month, from: monthDate) - 1)
                    let stepCount = Int(steps(for: monthDate)) ?? 0
                    
                    data.insert((monthName, stepCount), at: 0)
                }
            }
            
        default:
            break
        }
        
        return data
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Section {
                        DetailHeaderView(Header(title: steps(for: Date()), subtitle: String(bleManager.stepCountGoal), units: "Steps", icon: "figure.walk", accent: .blue), width: geo.size.width) {
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
                            ForEach(0...3, id: \.self) { index in
                                Text({
                                    switch index {
                                    case 0: return "W"  // Weekly
                                    case 1: return "M"  // Monthly
                                    case 2: return "6M" // 6 Months
                                    case 3: return "Y"  // Yearly
                                    default: return "-"
                                    }
                                }())
                                .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section {
                        Chart {
                            ForEach(stepsForSelection(), id: \.0) { (label, stepCount) in
                                BarMark(
                                    x: .value("Label", label),
                                    y: .value("Steps", stepCount)
                                )
                            }
                        }
                        .frame(height: 230)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Steps")
        .toolbar {
            
        }
    }
}

#Preview {
    StepsView()
}
