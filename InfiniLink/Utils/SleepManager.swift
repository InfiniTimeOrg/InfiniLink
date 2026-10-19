//
//  SleepManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreData
import SwiftUI
import HealthKit

class SleepManager: ObservableObject {
    static let shared = SleepManager()

    let persistenceController = PersistenceController.shared
    let deviceManager = DeviceManager.shared

    @Published private(set) var isProcessing = false

    private var lastProcessedDate: Date?
    private let processingInterval: TimeInterval = 60 * 15
    private let initialNightsToProcess = 7

    private var finalizedKey: String {
        "sleepFinalizedThrough-\(deviceManager.pairedDeviceID ?? "")"
    }

    // Needs background HR measurements, which were added in 1.16
    var isSupported: Bool {
        deviceManager.firmware.compare("1.16.0", options: .numeric) != .orderedAscending
    }
    
    // 5 or 10 min gives enough HR data overnight without killing the battery
    static let backgroundPeriods: [UInt16] = [300, 600]
    
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
        var windows = [DateInterval]()
        var window = latest
        for _ in 0..<initialNightsToProcess {
            guard window.end.timeIntervalSince1970 > finalizedThrough else { break }

            windows.insert(window, at: 0)
            // Recompute so daylight saving doesn't shift the window
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: window.start),
                  let previousWindow = SleepAnalyzer.window(containing: previous) else { break }
            window = previousWindow
        }

        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let daytimeMedian = self.daytimeMedian(deviceId: deviceId, context: context)
            var newlyFinalized = [SleepSession]()

            for window in windows {
                let activity = self.activity(in: window, deviceId: deviceId, context: context)
                let heartRates = self.heartRates(in: window, deviceId: deviceId, context: context)
                let detected = SleepAnalyzer.analyze(window: window, activity: activity, heartRates: heartRates, daytimeMedian: daytimeMedian)

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

    func states(for session: SleepSession) -> [SleepState] {
        guard let data = session.minutes else { return [] }

        return data.map { SleepState(rawValue: $0) ?? .noData }
    }

    func recentSessions(nights: Int = 7) -> [SleepSession] {
        guard let deviceId = deviceManager.pairedDeviceID,
              let latest = SleepAnalyzer.latestWindow(),
              let start = Calendar.current.date(byAdding: .day, value: -(nights - 1), to: latest.start) else { return [] }

        return sessions(in: DateInterval(start: start, end: latest.end), deviceId: deviceId, context: persistenceController.container.viewContext)
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

    private func daytimeMedian(deviceId: String, context: NSManagedObjectContext) -> Double? {
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return nil }
        
        return SleepAnalyzer.daytimeMedian(of: activity(in: DateInterval(start: start, end: Date()), deviceId: deviceId, context: context))
    }
}
