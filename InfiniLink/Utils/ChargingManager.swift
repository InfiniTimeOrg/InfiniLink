//
//  ChargingManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import Foundation
import ActivityKit
import UIKit

class ChargingManager {
    static let shared = ChargingManager()

    private let bleManager = BLEManager.shared

    private(set) var chargingSince: Date?
    private var lastChargeState: ChargeState?
    private var lastLevel: Double?

    private var settings: BatterySettings { NotificationSettingsManager.shared.settings.batterySettings }

    func update() {
        let state = bleManager.chargeState
        let wasOnCharger = lastChargeState == .charging || lastChargeState == .full
        defer {
            lastChargeState = state
            lastLevel = bleManager.batteryLevel
        }

        if bleManager.isOnCharger {
            if !wasOnCharger {
                chargingSince = Date()
                NotificationManager.shared.sendChargingDuringExerciseNotification()
            }
            if !wasOnCharger || state != lastChargeState || bleManager.batteryLevel != lastLevel {
                updateLiveActivity()
            }
        } else if wasOnCharger || state == nil {
            chargingSince = nil
            endLiveActivity()

            if wasOnCharger && state == .discharging {
                NotificationManager.shared.markMoved()
                NotificationManager.shared.sendUnpluggedNotification()
            }
        }
    }

    private func updateLiveActivity() {
        guard #available(iOS 16.2, *) else { return }
        guard settings.chargingLiveActivityEnabled, bleManager.hasLoadedBatteryLevel else {
            endLiveActivity()
            return
        }

        let level = bleManager.batteryLevel
        let isFull = bleManager.chargeState == .full || level >= 100
        let points = ChartManager.shared.batteryPoints(predicate: ChartManager.shared.ninetyDayPredicate)
        let fullAt = isFull ? nil : BatteryStats.timeUntilFull(from: points, currentLevel: level).map { Date().addingTimeInterval($0) }
        let uptime = BatteryStats.remainingUptime(from: points, currentLevel: level)
        let state = ChargingAttributes.ContentState(level: Int(level), isFull: isFull, fullAt: fullAt, uptime: uptime)

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(30 * 60), relevanceScore: 0)
        if let activity = Activity<ChargingAttributes>.activities.first {
            Task { @MainActor in
                let task = UIApplication.shared.beginBackgroundTask()
                defer { UIApplication.shared.endBackgroundTask(task) }

                await activity.update(content)
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                _ = try Activity.request(attributes: ChargingAttributes(deviceName: DeviceManager.shared.name), content: content, pushType: nil)
            } catch {
                log("Failed to start charging Live Activity: \(error.localizedDescription)", caller: "ChargingManager")
            }
        }
    }

    private func endLiveActivity() {
        guard #available(iOS 16.2, *) else { return }

        Task {
            for activity in Activity<ChargingAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
