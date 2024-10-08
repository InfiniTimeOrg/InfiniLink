//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI
import Accelerate
import CoreData

struct HeartView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var weekDaySelection = 0
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    var heartPointValues: [Double] {
        return heartPoints.compactMap({ $0.value })
    }
    let emptyValue = "--"
    
    func heartRate(for val: Double) -> String {
        return val > 0 ? String(format: "%.0f", val) : emptyValue
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        DetailHeaderView(Header(title: String(format: "%.0f", bleManager.heartRate == 0 ? heartPointValues.last ?? 0 : bleManager.heartRate), titleUnits: "BPM", icon: "heart.fill", accent: .red), width: geo.size.width, animation: bleManager.isHeartRateBeingRead ? .heart : nil) {
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
                    .listRowBackground(Color.clear)
                    VStack {
                        Picker("Range", selection: $weekDaySelection) {
                            ForEach(0...6, id: \.self) { index in
                                Text({
                                    switch index {
                                    case 0: return "H"
                                    case 1: return "D"
                                    case 2: return "W"
                                    case 3: return "M"
                                    case 4: return "T"
                                    case 5: return "6M"
                                    case 6: return "Y"
                                    default: return ""
                                    }
                                }())
                                .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        // TODO: add chart
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
        .onChange(of: heartPointValues) { vals in
            print(heartPointValues)
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
