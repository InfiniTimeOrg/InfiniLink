//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import Accelerate
import CoreData
import SwiftUICharts

struct HeartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartDataPoints: FetchedResults<HeartDataPoint>
    
    var heartPointValues: [Double] {
        return chartManager.heartPoints().compactMap({ $0.value })
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
    func timestamp(for heartPoint: HeartDataPoint?) -> String? {
        guard let timeInterval = heartPoint?.timestamp?.timeIntervalSinceNow else { return "" }
        
        return units(for: Int(abs(timeInterval)))
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Section {
                        DetailHeaderView(Header(title: String(format: "%.0f", heartPointValues.last ?? 0), subtitle: timestamp(for: chartManager.heartPoints().last), units: "BPM", icon: "heart.fill", accent: .red), width: geo.size.width, animate: true) {
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
                            ForEach(0...3, id: \.self) { index in
                                Text({
                                    switch index {
                                    case 0: return "H"
                                    case 1: return "D"
                                    case 2: return "W"
                                    case 3: return "M"
                                    default: return "-"
                                    }
                                }())
                                .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section {
                        HeartChartView(heartPoints: chartManager.heartPoints())
                            .frame(height: geo.size.width / 1.6)
                            .padding(.vertical)
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
