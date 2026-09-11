//
//  BatteryStats.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import Foundation

// We don't have a precise charge/discharge state over ble (yet) so we're just inferring it for now
struct BatteryCycleStats {
    let normalizedDuration: TimeInterval? // estimate a full cycle even if we haven't tracked a full one (0-100 or 100-0)
    let averageSessionDuration: TimeInterval? // average of the sessions actually tracked
    let sessionCount: Int

    var hasData: Bool { sessionCount > 0 }
}

enum BatteryStats {
    private static let noiseThresholdPercent: Double = 1
    private static let minSessionPercent: Double = 5
    private static let maxChargeGap: TimeInterval = 3 * 3600
    private static let maxDischargeGap: TimeInterval = 24 * 3600

    private struct Session {
        let duration: TimeInterval
        let percentDelta: Double
    }

    private static func sessions(from points: [BatteryDataPoint], charging: Bool) -> [Session] {
        let readings = points
            .compactMap { point -> (date: Date, value: Double)? in
                guard let timestamp = point.timestamp else { return nil }
                return (timestamp, point.value)
            }
            .sorted { $0.date < $1.date }

        guard readings.count > 1 else { return [] }

        let maxGap = charging ? maxChargeGap : maxDischargeGap

        var sessions: [Session] = []
        var runStart = readings[0]
        var previous = readings[0]

        func flush(at end: (date: Date, value: Double)) {
            let percentDelta = end.value - runStart.value
            let duration = end.date.timeIntervalSince(runStart.date)

            if abs(percentDelta) >= minSessionPercent, duration > 0 {
                sessions.append(Session(duration: duration, percentDelta: percentDelta))
            }
        }

        for reading in readings.dropFirst() {
            let gap = reading.date.timeIntervalSince(previous.date)
            let delta = reading.value - previous.value
            let isRising: Bool? = delta > noiseThresholdPercent ? true : (delta < -noiseThresholdPercent ? false : nil)

            if gap > maxGap || (isRising != nil && isRising != charging) {
                flush(at: previous)
                runStart = reading
            }

            previous = reading
        }
        flush(at: previous)

        return sessions.filter { charging ? $0.percentDelta > 0 : $0.percentDelta < 0 }
    }

    private static func cycleStats(from points: [BatteryDataPoint], charging: Bool) -> BatteryCycleStats {
        let sessions = sessions(from: points, charging: charging)

        guard !sessions.isEmpty else {
            return BatteryCycleStats(normalizedDuration: nil, averageSessionDuration: nil, sessionCount: 0)
        }

        let totalPercent = sessions.reduce(0) { $0 + abs($1.percentDelta) }
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let averageSessionDuration = totalDuration / Double(sessions.count)
        let normalizedDuration = totalPercent > 0 ? (totalDuration / totalPercent) * 100 : nil

        return BatteryCycleStats(normalizedDuration: normalizedDuration, averageSessionDuration: averageSessionDuration, sessionCount: sessions.count)
    }

    static func chargeStats(from points: [BatteryDataPoint]) -> BatteryCycleStats {
        cycleStats(from: points, charging: true)
    }

    static func dischargeStats(from points: [BatteryDataPoint]) -> BatteryCycleStats {
        cycleStats(from: points, charging: false)
    }

    static func remainingUptime(from points: [BatteryDataPoint], currentLevel: Double) -> TimeInterval? {
        guard let fullCycle = dischargeStats(from: points).normalizedDuration else { return nil }
        return (fullCycle / 100) * currentLevel
    }
}
