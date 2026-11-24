//
//  BatteryStats.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import Foundation

struct BatteryCycleStats { // Infer charging state from level changes when the firmware doesn't report it
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
        let start: Date
        let end: Date
        let percentDelta: Double

        var duration: TimeInterval { end.timeIntervalSince(start) }
    }

    private typealias Reading = (date: Date, value: Double, state: ChargeState?)

    private static func readings(from points: [BatteryDataPoint]) -> [Reading] {
        points
            .compactMap { point -> Reading? in
                guard let timestamp = point.timestamp else { return nil }
                return (timestamp, point.value, ChargeState(rawValue: point.chargeState))
            }
            .sorted { $0.date < $1.date }
    }

    private static func sessions(from points: [BatteryDataPoint], charging: Bool) -> [Session] {
        let readings = readings(from: points)

        var sessions: [Session] = []
        var run: [Reading] = []
        for reading in readings {
            if let last = run.last, (last.state == nil) != (reading.state == nil) {
                sessions += last.state == nil ? inferredSessions(from: run, charging: charging) : reportedSessions(from: run + [reading], charging: charging)
                run = []
            }
            run.append(reading)
        }
        if let last = run.last {
            sessions += last.state == nil ? inferredSessions(from: run, charging: charging) : reportedSessions(from: run, charging: charging)
        }

        return sessions.filter { abs($0.percentDelta) >= minSessionPercent && (charging ? $0.percentDelta > 0 : $0.percentDelta < 0) }
    }

    private static func reportedSessions(from readings: [Reading], charging: Bool) -> [Session] {
        let maxGap = charging ? maxChargeGap : maxDischargeGap

        var sessions: [Session] = []
        var runStart: Reading?
        var previous: Reading?
        for reading in readings {
            let matches = reading.state == (charging ? .charging : .discharging)
            if let start = runStart, let previous, !matches || reading.date.timeIntervalSince(previous.date) > maxGap {
                let end = matches ? previous : reading
                if end.date > start.date {
                    sessions.append(Session(start: start.date, end: end.date, percentDelta: end.value - start.value))
                }
                runStart = nil
            }
            if matches && runStart == nil {
                runStart = reading
            }
            previous = reading
        }
        if let start = runStart, let previous, previous.date > start.date {
            sessions.append(Session(start: start.date, end: previous.date, percentDelta: previous.value - start.value))
        }

        return sessions
    }

    private static func inferredSessions(from readings: [Reading], charging: Bool) -> [Session] {
        guard readings.count > 1 else { return [] }

        let maxGap = charging ? maxChargeGap : maxDischargeGap

        var sessions: [Session] = []
        var runStart = readings[0]
        var previous = readings[0]

        func flush(at end: Reading) {
            if end.date > runStart.date {
                sessions.append(Session(start: runStart.date, end: end.date, percentDelta: end.value - runStart.value))
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

        return sessions
    }

    static func chargerIntervals(from points: [BatteryDataPoint], now: Date = Date()) -> [DateInterval] {
        var intervals: [DateInterval] = []
        var start: Date?
        var previous: Reading?
        for reading in readings(from: points) {
            let onCharger = reading.state == .charging || reading.state == .full
            if let runStart = start, let previous, !onCharger || reading.date.timeIntervalSince(previous.date) > maxChargeGap {
                intervals.append(DateInterval(start: runStart, end: onCharger ? previous.date : reading.date))
                start = nil
            }
            if onCharger && start == nil {
                start = reading.date
            }
            previous = reading
        }
        if let start, let previous {
            let end = now.timeIntervalSince(previous.date) > maxChargeGap ? previous.date : now
            intervals.append(DateInterval(start: start, end: max(start, end)))
        }

        return intervals
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

    static func timeUntilFull(from points: [BatteryDataPoint], currentLevel: Double) -> TimeInterval? {
        guard let fullCycle = chargeStats(from: points).normalizedDuration else { return nil }
        return (fullCycle / 100) * (100 - currentLevel)
    }
    
    static func timeSinceLastCharge(from points: [BatteryDataPoint]) -> TimeInterval? {
        guard let charge = sessions(from: points, charging: true).last else { return nil }
        return Date().timeIntervalSince(charge.end)
    }
    
    static func format(_ duration: TimeInterval?, maximumUnitCount: Int = 2) -> String {
        guard let duration, duration.isFinite, duration > 0 else { return "--" }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated

        if duration >= 86400 {
            formatter.allowedUnits = [.day, .hour]
            formatter.maximumUnitCount = 2
        } else {
            formatter.allowedUnits = [.hour, .minute]
            formatter.maximumUnitCount = maximumUnitCount
        }

        return formatter.string(from: duration) ?? "--"
    }
}
