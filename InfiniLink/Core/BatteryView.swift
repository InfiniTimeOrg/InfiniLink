//
//  BatteryView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//
//  Renamed from BatterySettingsView.swift by Titus Kendzorra on 07.10.2026

import SwiftUI

struct BatteryView: View {
    @ObservedObject private var bleManager = BLEManager.shared
    
    @State private var points = [BatteryDataPoint]()
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(format: "%.0f", bleManager.batteryLevel), units: "%", icon: {
                        if bleManager.batteryLevel > 75 {
                            return "battery.100percent"
                        } else if bleManager.batteryLevel > 50 {
                            return "battery.75percent"
                        } else if bleManager.batteryLevel > 25 {
                            return "battery.50percent"
                        } else if bleManager.batteryLevel == 0 {
                            return "battery.0percent"
                        } else {
                            return "battery.25percent"
                        }
                    }(), accent: bleManager.batteryLevel.batteryColor), width: geo.size.width) {
                        Color.clear
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                } footer: {
                    // does not work
                    if let remaining = BatteryStats.currentUptime(from: points), remaining > 0 {
                        Text("~\(format(remaining)) left")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                BatteryChartView()
                BatteryStatsSectionView()
                .navigationTitle("Battery")
            }
            .toolbar {
                NavigationLink {
                    BatterySettingsView()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

private func format(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated

        if duration >= 86400 {
            formatter.allowedUnits = [.day, .hour]
            formatter.maximumUnitCount = 2
        } else {
            formatter.allowedUnits = [.hour, .minute]
            formatter.maximumUnitCount = 1
        }

        return formatter.string(from: duration) ?? "--"
    }

#Preview {
    NavigationStack {
        BatteryView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
