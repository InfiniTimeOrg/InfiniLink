//
//  BatteryStatsSectionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import SwiftUI

struct BatteryStatsSectionView: View {
    @ObservedObject var bleManager = BLEManager.shared

    @State private var points: [BatteryDataPoint] = []

    private var chargeStats: BatteryCycleStats {
        BatteryStats.chargeStats(from: points)
    }
    private var dischargeStats: BatteryCycleStats {
        BatteryStats.dischargeStats(from: points)
    }
    private var remainingUptime: TimeInterval? {
        BatteryStats.remainingUptime(from: points, currentLevel: bleManager.batteryLevel)
    }
    private var hasAnyData: Bool {
        chargeStats.hasData || dischargeStats.hasData
    }

    private func format(_ duration: TimeInterval?) -> String {
        guard let duration, duration.isFinite, duration > 0 else { return "--" }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.allowedUnits = duration >= 86400 ? [.day, .hour] : [.hour, .minute]

        return formatter.string(from: duration) ?? "--"
    }

    private func row(_ title: LocalizedStringKey, value: String, secondary: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                if let secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var body: some View {
        Section {
            if hasAnyData {
                row(
                    "Average Charge Time",
                    value: format(chargeStats.averageSessionDuration),
                    secondary: chargeStats.normalizedDuration.map { "~\(format($0)) to full" }
                )
                row(
                    "Average Discharge Time",
                    value: format(dischargeStats.averageSessionDuration),
                    secondary: dischargeStats.normalizedDuration.map { "~\(format($0)) full cycle" }
                )
                row(
                    "Estimated Battery Uptime",
                    value: format(dischargeStats.normalizedDuration),
                    secondary: remainingUptime.map { "~\(format($0)) left at \(Int(bleManager.batteryLevel))%" }
                )
            } else {
                Text("Not enough charge history yet. Check back after a few charge cycles.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Battery Health")
        } footer: {
            Text("Estimated from the last 90 days of charge and discharge history.")
        }
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

#Preview {
    List {
        BatteryStatsSectionView()
    }
}
