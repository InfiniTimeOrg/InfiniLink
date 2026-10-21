//
//  BatteryStatsSectionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import SwiftUI

struct BatteryStatsSectionView: View {
    @ObservedObject var bleManager = BLEManager.shared

    let points: [BatteryDataPoint]

    private var chargeStats: BatteryCycleStats {
        BatteryStats.chargeStats(from: points)
    }
    private var dischargeStats: BatteryCycleStats {
        BatteryStats.dischargeStats(from: points)
    }
    private var timeSinceLastCharge: TimeInterval? {
        BatteryStats.timeSinceLastCharge(from: points)
    }
    private var hasAnyData: Bool {
        chargeStats.hasData || dischargeStats.hasData
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
                    "Last Charged",
                    value: timeSinceLastCharge.map { interval in
                        interval < 60
                            ? String(localized: "Now")
                            : Date(timeIntervalSinceNow: -interval).formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
                    } ?? "--",
                    secondary: nil
                )
                row(
                    "Average Charge Time",
                    value: BatteryStats.format(chargeStats.averageSessionDuration),
                    secondary: chargeStats.normalizedDuration.map { String(localized: "~\(BatteryStats.format($0)) to full") }
                )
                row(
                    "Average Discharge Time",
                    value: BatteryStats.format(dischargeStats.averageSessionDuration),
                    secondary: dischargeStats.normalizedDuration.map { String(localized: "~\(BatteryStats.format($0)) full cycle") }
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
    }
}

#Preview {
    List {
        BatteryStatsSectionView(points: [])
    }
}
