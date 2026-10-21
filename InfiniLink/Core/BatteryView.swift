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
    
    @State private var points: [BatteryDataPoint] = []
    
    private var remainingText: String? {
        guard let remaining = BatteryStats.remainingUptime(from: points, currentLevel: bleManager.batteryLevel), remaining > 0 else { return nil }
        return String(localized: "~\(BatteryStats.format(remaining, maximumUnitCount: 1)) left   ")
        // this string unfortunately needs some trailing spaces for visual alignment, since the visual focus is on the remaining time and the ~ appears to shift the entire string to the right.
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: String(format: "%.0f", bleManager.batteryLevel), subtitle: remainingText, units: "%", icon: {
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
                }
                .listRowBackground(Color.clear)
                BatteryChartView()
                BatteryStatsSectionView(points: points)
            }
        }
        .navigationTitle("Battery")
        .onAppear {
            fetch()
        }
        .onChange(of: bleManager.batteryLevel) { _ in
            fetch()
        }
    }
    
    private func fetch() {
        points = ChartManager.shared.batteryPoints(predicate: ChartManager.shared.ninetyDayPredicate)
    }
}
