//
//  SleepManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreData
import SwiftUI
import HealthKit

struct SleepSchedule: Codable {
    var enabled = false
    var bedtime = 22 * 60 + 30 // Minutes after midnight
    var wake = 6 * 60 + 30
    var days = Array(1...7) // Calendar weekdays, 1 is Sunday

    var goalMinutes: Int {
        (wake - bedtime + 1440) % 1440
    }

    // Falling asleep takes a bit, so give some slack
    func meetsGoal(asleepMinutes: Int) -> Bool {
        asleepMinutes >= goalMinutes - 30
    }

    static func time(_ minute: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute())
    }
}

class SleepManager: ObservableObject {
    static let shared = SleepManager()

    let persistenceController = PersistenceController.shared
    let deviceManager = DeviceManager.shared

    @Published private(set) var isProcessing = false
    @Published var schedule: SleepSchedule {
        didSet {
            guard let data = try? JSONEncoder().encode(schedule) else { return }
            UserDefaults.standard.set(data, forKey: "sleepSchedule")
        }
    }

    private var lastProcessedDate: Date?
    private let processingInterval: TimeInterval = 60 * 15
    private let initialNightsToProcess = 7

    init() {
        if let data = UserDefaults.standard.data(forKey: "sleepSchedule"),
           let decoded = try? JSONDecoder().decode(SleepSchedule.self, from: data) {
            schedule = decoded
        } else {
            schedule = SleepSchedule()
        }
    }

    private var dismissedNapsKey: String {
        "dismissedNaps-\(deviceManager.pairedDeviceID ?? "")"
    }

    private var finalizedKey: String {
        "sleepFinalizedThrough-\(deviceManager.pairedDeviceID ?? "")"
    }

    // Needs background HR measurements, which were added in 1.16
    var isSupported: Bool {
        deviceManager.firmware.compare("1.16.0", options: .numeric) != .orderedAscending
    }
    
    // Continuous up to every 10 min gives enough HR data overnight
    static let backgroundPeriods: [UInt16] = [0, 30, 60, 300, 600]
    
    var hasRequiredMeasurements: Bool {
        deviceManager.heartRateBackgroundPeriod.map { Self.backgroundPeriods.contains(UInt16(clamping: $0)) } ?? false
    }
    
    // This gets called a lot, so only run every 15 minutes
    func processIfNeeded() {
        guard isSupported, hasRequiredMeasurements, Date().timeIntervalSince(lastProcessedDate ?? .distantPast) >= processingInterval else { return }

        process()
    }

    func process(completion: (() -> Void)? = nil) {
        guard let deviceId = deviceManager.pairedDeviceID, !isProcessing, let latest = SleepAnalyzer.latestWindow() else {
            completion?()
            return
        }

        isProcessing = true
        lastProcessedDate = Date()

        let finalizedThrough = UserDefaults.standard.double(forKey: finalizedKey)
        // Naps need a schedule to tell them apart from nights
        var periods = [(interval: DateInterval, nightBefore: DateInterval?)]()
        var window = latest
        for _ in 0..<initialNightsToProcess {
            if schedule.enabled, window.end < Date(),
               let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: window.start),
               let next = SleepAnalyzer.window(containing: nextDay),
               next.start > window.end, next.start.timeIntervalSince1970 > finalizedThrough {
                periods.insert((DateInterval(start: window.end, end: next.start), window), at: 0)
            }
            guard window.end.timeIntervalSince1970 > finalizedThrough else { break }

            periods.insert((window, nil), at: 0)
            // Recompute so daylight saving doesn't shift the window
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: window.start),
                  let previousWindow = SleepAnalyzer.window(containing: previous) else { break }
            window = previousWindow
        }

        let dismissedNaps = UserDefaults.standard.array(forKey: dismissedNapsKey) as? [[Double]] ?? []

        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let daytimeMedian = self.daytimeMedian(deviceId: deviceId, context: context)
            var newlyFinalized = [SleepSession]()

            for (window, nightBefore) in periods {
                let activity = self.activity(in: window, deviceId: deviceId, context: context)
                let heartRates = self.heartRates(in: window, deviceId: deviceId, context: context)
                var detected = [DetectedSleep]()
                if let nightBefore {
                    // Need last night's HR to compare against
                    if let sleepingHeartRate = self.sleepingHeartRate(in: nightBefore, deviceId: deviceId, context: context) {
                        detected = SleepAnalyzer.analyze(window: window, activity: activity, heartRates: heartRates, daytimeMedian: daytimeMedian, sleepingHeartRate: sleepingHeartRate).filter { nap in
                            !dismissedNaps.contains { nap.start.timeIntervalSince1970 < $0[1] && nap.end.timeIntervalSince1970 > $0[0] }
                        }
                    }
                } else {
                    detected = SleepAnalyzer.analyze(window: window, activity: activity, heartRates: heartRates, daytimeMedian: daytimeMedian)
                }

                // Redo the whole night each time so late data replaces the first guess
                for existing in self.sessions(in: window, deviceId: deviceId, context: context) {
                    context.delete(existing)
                }

                let isFinal = Date() >= window.end
                for sleep in detected {
                    let session = SleepSession(context: context)
                    session.id = UUID()
                    session.deviceId = deviceId
                    session.start = sleep.start
                    session.end = sleep.end
                    session.asleepMinutes = Int32(sleep.asleepMinutes)
                    session.awakeMinutes = Int32(sleep.awakeMinutes)
                    session.minutes = Data(sleep.minutes.map { $0.rawValue })
                    session.isNap = nightBefore != nil

                    if isFinal {
                        newlyFinalized.append(session)
                    }
                }

                if isFinal {
                    UserDefaults.standard.set(window.end.timeIntervalSince1970, forKey: self.finalizedKey)
                }
            }

            do {
                try context.save()
            } catch {
                log("Error saving sleep sessions: \(error.localizedDescription)", caller: "SleepManager")
            }

            // Only write finished nights to Apple Health so they never get written twice
            for session in newlyFinalized {
                let objectID = session.objectID
                HealthKitManager.shared.writeSleep(start: session.start ?? Date(), minutes: self.states(for: session)) { success in
                    guard success else { return }

                    context.perform {
                        (try? context.existingObject(with: objectID) as? SleepSession)?.syncedToHealth = true
                        try? context.save()
                    }
                }
            }

            DispatchQueue.main.async {
                self.isProcessing = false
                completion?()
            }
        }
    }

    func generateTestSession() {
        guard let deviceId = deviceManager.pairedDeviceID else { return }

        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-Double.random(in: 30...120) * 60)
        guard let window = SleepAnalyzer.window(containing: start) else { return }

        let target = Int.random(in: 390...510)
        var minutes = [SleepState]()
        repeat {
            if !minutes.isEmpty {
                let unmeasurable = Int.random(in: 0..<5) == 0
                minutes += Array(repeating: unmeasurable ? .noData : .awake, count: unmeasurable ? Int.random(in: 15...40) : Int.random(in: 2...10))
            }
            minutes += Array(repeating: .asleep, count: Int.random(in: 30...90))
        } while minutes.count < target

        let context = persistenceController.container.viewContext
        for existing in sessions(in: window, deviceId: deviceId, context: context) where !existing.isNap {
            context.delete(existing)
        }

        func addSession(start: Date, minutes: [SleepState], isNap: Bool) {
            let session = SleepSession(context: context)
            session.id = UUID()
            session.deviceId = deviceId
            session.start = start
            session.end = start.addingTimeInterval(Double(minutes.count) * 60)
            session.asleepMinutes = Int32(minutes.filter { $0 == .asleep }.count)
            session.awakeMinutes = Int32(minutes.filter { $0 == .awake }.count)
            session.minutes = Data(minutes.map { $0.rawValue })
            session.isNap = isNap
        }

        addSession(start: start, minutes: minutes, isNap: false)

        // Naps go in the gaps between nights so processing the night doesn't wipe them
        let calendar = Calendar.current
        let nights = [-1, 0, 1].compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: window.start).flatMap { SleepAnalyzer.window(containing: $0) }
        }
        for (night, next) in zip(nights, nights.dropFirst()) where next.start > night.end {
            let asleep = Int.random(in: 20...80)
            let awakeAt = Int.random(in: 5..<asleep)
            let napMinutes = Array(repeating: SleepState.asleep, count: awakeAt) + Array(repeating: .awake, count: Int.random(in: 0...4)) + Array(repeating: .asleep, count: asleep - awakeAt)

            // Somewhere in the gap that's already happened
            let latest = min(next.start, Date()).addingTimeInterval(-Double(napMinutes.count + 30) * 60)
            let earliest = night.end.addingTimeInterval(30 * 60)
            guard latest > earliest else { continue }

            for existing in sessions(in: DateInterval(start: night.end, end: next.start), deviceId: deviceId, context: context) where existing.isNap {
                context.delete(existing)
            }
            addSession(start: Date(timeIntervalSince1970: .random(in: earliest.timeIntervalSince1970...latest.timeIntervalSince1970)), minutes: napMinutes, isNap: true)
        }

        // Test naps have no data behind them, so don't let processing redo today and wipe them
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? window.end
        UserDefaults.standard.set(max(UserDefaults.standard.double(forKey: finalizedKey), window.end.timeIntervalSince1970, endOfToday.timeIntervalSince1970), forKey: finalizedKey)

        do {
            try context.save()
        } catch {
            log("Error saving test sleep session: \(error.localizedDescription)", caller: "SleepManager")
        }
    }

    // Remember it so it doesn't come back next time we process
    func deleteNap(_ nap: SleepSession) {
        guard let start = nap.start, let end = nap.end else { return }

        let cutoff = Date().addingTimeInterval(-8 * 86400).timeIntervalSince1970
        let dismissed = (UserDefaults.standard.array(forKey: dismissedNapsKey) as? [[Double]] ?? []).filter { $0[1] > cutoff }
        UserDefaults.standard.set(dismissed + [[start.timeIntervalSince1970, end.timeIntervalSince1970]], forKey: dismissedNapsKey)

        let context = persistenceController.container.viewContext
        context.delete(nap)
        do {
            try context.save()
        } catch {
            log("Error deleting nap: \(error.localizedDescription)", caller: "SleepManager")
        }
    }

    func states(for session: SleepSession) -> [SleepState] {
        guard let data = session.minutes else { return [] }

        return data.map { SleepState(rawValue: $0) ?? .noData }
    }

    func recentSessions(nights: Int = 7) -> [SleepSession] {
        guard let deviceId = deviceManager.pairedDeviceID,
              let latest = SleepAnalyzer.latestWindow(),
              let start = Calendar.current.date(byAdding: .day, value: -(nights - 1), to: latest.start) else { return [] }

        // Go up to now so today's naps show
        return sessions(in: DateInterval(start: start, end: max(latest.end, Date())), deviceId: deviceId, context: persistenceController.container.viewContext)
    }

    private func sessions(in window: DateInterval, deviceId: String, context: NSManagedObjectContext) -> [SleepSession] {
        let request: NSFetchRequest<SleepSession> = SleepSession.fetchRequest()
        request.predicate = NSPredicate(format: "deviceId == %@ AND start >= %@ AND start < %@", deviceId, window.start as NSDate, window.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    private func activity(in window: DateInterval, deviceId: String, context: NSManagedObjectContext) -> [(date: Date, value: Double)] {
        let request: NSFetchRequest<MotionActivityPoint> = MotionActivityPoint.fetchRequest()
        request.predicate = NSPredicate(format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@", deviceId, window.start as NSDate, window.end as NSDate)

        return ((try? context.fetch(request)) ?? []).compactMap { point in
            guard let date = point.timestamp else { return nil }
            return (date, point.value)
        }
    }

    private func heartRates(in window: DateInterval, deviceId: String, context: NSManagedObjectContext) -> [(date: Date, value: Double)] {
        let request: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
        request.predicate = NSPredicate(format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@", deviceId, window.start as NSDate, window.end as NSDate)

        return ((try? context.fetch(request)) ?? []).compactMap { point in
            guard let date = point.timestamp else { return nil }
            return (date, point.value)
        }
    }

    private func sleepingHeartRate(in night: DateInterval, deviceId: String, context: NSManagedObjectContext) -> Double? {
        let rates = sessions(in: night, deviceId: deviceId, context: context).filter { !$0.isNap }.flatMap { session -> [Double] in
            guard let start = session.start, let end = session.end else { return [] }
            return heartRates(in: DateInterval(start: start, end: end), deviceId: deviceId, context: context).map(\.value).filter { $0 > 0 }
        }

        return SleepAnalyzer.median(rates)
    }

    private func daytimeMedian(deviceId: String, context: NSManagedObjectContext) -> Double? {
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return nil }
        
        return SleepAnalyzer.daytimeMedian(of: activity(in: DateInterval(start: start, end: Date()), deviceId: deviceId, context: context))
    }
}
