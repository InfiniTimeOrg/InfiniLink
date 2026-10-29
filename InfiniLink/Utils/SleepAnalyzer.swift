//
//  SleepAnalyzer.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation

enum SleepState: UInt8, CaseIterable {
    case awake = 0
    case asleep = 1
    case noData = 2
}

struct DetectedSleep {
    let start: Date
    let minutes: [SleepState] // One entry per minute from start

    var end: Date {
        start.addingTimeInterval(Double(minutes.count) * 60)
    }
    var asleepMinutes: Int {
        minutes.filter { $0 == .asleep }.count
    }
    var awakeMinutes: Int {
        minutes.filter { $0 == .awake }.count
    }
}

struct SleepAnalyzer {
    // These are first guesses, need tuning with real nights (INL-84)
    static let windowStartHour = 18
    static let windowEndHour = 12
    static let scheduleMarginMinutes = 180 // Wiggle room around the schedule
    static let stillFractionOfDaytime = 0.15 // A minute counts as still below this fraction of the median daytime activity
    static let fallbackStillThreshold = 2000.0 // Used until there's enough daytime activity to compare against
    static let heartRateAwakeMargin = 15.0 // BPM above the night's baseline that counts as awake
    static let surroundingMinutes = 7 // Minutes on each side used to decide if a minute is awake
    static let awakeActiveFraction = 0.5 // Awake when at least this much of the surrounding minutes are active
    static let minimumRunMinutes = 20
    static let maximumGapMinutes = 30
    static let minimumSessionMinutes = 60
    static let minimumNotWornMinutes = 15 // Still with no HR this long means the watch is off, since HR is reliable when still
    static let maximumFilledGapMinutes = 10
    static let minimumNapMinutes = 20
    static let napHeartRateMargin = 10.0 // How far above last night's sleeping HR a nap can be
    static let napHeartRateMinutes = 10 // HR is measured at least every 10 min

    // In minutes after midnight, 6pm to noon without a schedule
    static var windowMinutes: (start: Int, end: Int) {
        let schedule = SleepManager.shared.schedule
        guard schedule.enabled else { return (windowStartHour * 60, windowEndHour * 60) }

        return ((schedule.bedtime - scheduleMarginMinutes + 1440) % 1440, (schedule.wake + scheduleMarginMinutes) % 1440)
    }

    static func window(containing date: Date) -> DateInterval? {
        let calendar = Calendar.current
        let (startMinute, endMinute) = windowMinutes

        // Tonight's or last night's
        for offset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: offset, to: date),
                  let start = calendar.date(bySettingHour: startMinute / 60, minute: startMinute % 60, second: 0, of: day),
                  let endDay = endMinute > startMinute ? day : calendar.date(byAdding: .day, value: 1, to: day),
                  let end = calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0, of: endDay) else { continue }

            if start <= date && date < end {
                return DateInterval(start: start, end: end)
            }
        }
        return nil
    }

    static func latestWindow(before date: Date = Date()) -> DateInterval? {
        if let current = window(containing: date) {
            return current
        }

        // We're between nights, so use the last one
        let calendar = Calendar.current
        let endMinute = windowMinutes.end
        guard var end = calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0, of: date) else { return nil }
        if end > date {
            end = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        }

        return window(containing: end.addingTimeInterval(-60))
    }

    // Passing sleepingHeartRate looks for naps instead
    static func analyze(window: DateInterval, activity: [(date: Date, value: Double)], heartRates: [(date: Date, value: Double)], daytimeMedian: Double?, sleepingHeartRate: Double? = nil) -> [DetectedSleep] {
        let minuteCount = Int(min(window.end, Date()).timeIntervalSince(window.start) / 60)
        guard minuteCount > 0 else { return [] }

        func minuteIndex(_ date: Date) -> Int? {
            let index = Int(date.timeIntervalSince(window.start) / 60)
            return (0..<minuteCount).contains(index) ? index : nil
        }

        var activityByMinute = [Double?](repeating: nil, count: minuteCount)
        for point in activity {
            if let index = minuteIndex(point.date) {
                activityByMinute[index] = point.value
            }
        }

        var heartByMinute = [Double?](repeating: nil, count: minuteCount)
        for point in heartRates where point.value > 0 {
            if let index = minuteIndex(point.date) {
                heartByMinute[index] = point.value
            }
        }

        let stillThreshold = stillThreshold(daytimeMedian: daytimeMedian)

        // A watch on a table still reads as still so missing HR is what shows it's not being worn
        var runStart: Int?
        var flatCount = 0
        for index in 0...minuteCount {
            if index < minuteCount && activityByMinute[index] == nil && heartByMinute[index] == nil {
                continue // Dropped connection
            }
            let isFlat = index < minuteCount && (activityByMinute[index] ?? .infinity) < stillThreshold && heartByMinute[index] == nil
            if isFlat {
                runStart = runStart ?? index
                flatCount += 1
            } else if let start = runStart {
                if flatCount >= minimumNotWornMinutes {
                    for flat in start..<index {
                        activityByMinute[flat] = nil
                    }
                }
                runStart = nil
                flatCount = 0
            }
        }

        // HR well above the night's baseline means they're awake, even if they're still
        let nightRates = heartByMinute.compactMap { $0 }.sorted()
        let awakeHeartRate = nightRates.count >= 10 ? nightRates[nightRates.count / 5] + heartRateAwakeMargin : .infinity

        var isActive = [Bool?](repeating: nil, count: minuteCount)
        var lastHeartRate: (index: Int, value: Double)?
        for index in 0..<minuteCount {
            if let value = heartByMinute[index] {
                lastHeartRate = (index, value)
            }
            guard let value = activityByMinute[index] else { continue }

            if let sleepingHeartRate {
                // Sitting still looks like a nap, so HR has to be close to sleeping too
                let recent = lastHeartRate.flatMap { index - $0.index <= napHeartRateMinutes ? $0.value : nil }
                isActive[index] = value >= stillThreshold || (recent ?? .infinity) > sleepingHeartRate + napHeartRateMargin
            } else {
                isActive[index] = value >= stillThreshold || (heartByMinute[index] ?? 0) > awakeHeartRate
            }
        }

        // Brief movements are normal while asleep, so only call a minute awake when most of the minutes around it are active
        var states = [SleepState](repeating: .noData, count: minuteCount)
        for index in 0..<minuteCount where isActive[index] != nil {
            let surrounding = isActive[max(0, index - surroundingMinutes)...min(minuteCount - 1, index + surroundingMinutes)].compactMap { $0 }
            let activeFraction = Double(surrounding.filter { $0 }.count) / Double(surrounding.count)
            states[index] = activeFraction >= awakeActiveFraction ? .awake : .asleep
        }

        // Absorb short gaps
        var gapStart: Int?
        for index in 0..<minuteCount {
            if states[index] == .noData {
                gapStart = gapStart ?? index
            } else if let start = gapStart {
                if start > 0 && index - start <= maximumFilledGapMinutes && states[start - 1] == states[index] {
                    for gap in start..<index {
                        states[gap] = states[index]
                    }
                }
                gapStart = nil
            }
        }

        return sessions(from: states, windowStart: window.start, minimumMinutes: sleepingHeartRate == nil ? minimumSessionMinutes : minimumNapMinutes)
    }

    private static func sessions(from states: [SleepState], windowStart: Date, minimumMinutes: Int) -> [DetectedSleep] {
        var runs = [Range<Int>]()
        var runStart: Int?
        var lastAsleep = 0
        var asleepCount = 0
        // Only awake minutes end a run, so a dropped connection doesn't cut off the end of the night
        for index in 0...states.count {
            let state = index < states.count ? states[index] : .awake
            if state == .asleep {
                runStart = runStart ?? index
                lastAsleep = index
                asleepCount += 1
            } else if state == .awake, let start = runStart {
                if asleepCount >= minimumRunMinutes {
                    runs.append(start..<lastAsleep + 1)
                }
                runStart = nil
                asleepCount = 0
            }
        }

        var merged = [Range<Int>]()
        for run in runs {
            // Missing data doesn't count toward the gap so a dropped connection doesn't split the night
            if let last = merged.last, states[last.upperBound..<run.lowerBound].filter({ $0 == .awake }).count <= maximumGapMinutes {
                merged[merged.count - 1] = last.lowerBound..<run.upperBound
            } else {
                merged.append(run)
            }
        }

        return merged.compactMap { range in
            let minutes = Array(states[range])
            let sleep = DetectedSleep(start: windowStart.addingTimeInterval(Double(range.lowerBound) * 60), minutes: minutes)

            return sleep.asleepMinutes >= minimumMinutes ? sleep : nil
        }
    }

    static func stillThreshold(daytimeMedian: Double?) -> Double {
        return daytimeMedian.map { $0 * stillFractionOfDaytime } ?? fallbackStillThreshold
    }
    
    static func daytimeMedian(of activity: [(date: Date, value: Double)]) -> Double? {
        let values = activity.compactMap { point -> Double? in
            let hour = Calendar.current.component(.hour, from: point.date)
            return (10..<20).contains(hour) ? point.value : nil
        }
        
        return values.count >= 180 ? median(values) : nil
    }
    
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }

        let sorted = values.sorted()
        return sorted[sorted.count / 2]
    }
}
