//
//  HealthTrends.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreData

struct RestingHeartRateDay: Identifiable {
    var id: Date { date }
    let date: Date
    let bpm: Double
}

struct HeartRateAverages {
    var awake: Double?
    var sleep: Double?
    var workout: Double?
}

struct HealthTrends {
    let persistenceController = PersistenceController.shared

    private let minimumSamples = 5

    func restingHeartRates(days: Int, deviceId: String, completion: @escaping ([RestingHeartRateDay]) -> Void) {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: Date())) else { return }

        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let range = DateInterval(start: start, end: Date())

            let heartRates = self.points(HeartDataPoint.self, in: range, deviceId: deviceId, context: context).compactMap { point in
                point.timestamp.map { (date: $0, value: point.value) }
            }
            let activity = self.points(MotionActivityPoint.self, in: range, deviceId: deviceId, context: context).compactMap { point in
                point.timestamp.map { (date: $0, value: point.value) }
            }
            let sleepIntervals = self.sleepIntervals(in: range, deviceId: deviceId, context: context)

            let stillThreshold = SleepAnalyzer.stillThreshold(daytimeMedian: SleepAnalyzer.daytimeMedian(of: activity))
            var activityByMinute = [Int: Double]()
            for point in activity {
                activityByMinute[Int(point.date.timeIntervalSince1970 / 60)] = point.value
            }

            // Heart rates are sorted so we can walk through them once
            var heartIndex = 0
            let result = (0..<days).compactMap { offset -> RestingHeartRateDay? in
                guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                      let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }

                let dayStartIndex = heartIndex
                while heartIndex < heartRates.count && heartRates[heartIndex].date < nextDay {
                    heartIndex += 1
                }

                let restingSamples = heartRates[dayStartIndex..<heartIndex].filter { sample in
                    guard sample.value > 0, sample.date >= day else { return false }

                    let hour = calendar.component(.hour, from: sample.date)
                    guard (6..<22).contains(hour), !sleepIntervals.contains(where: { $0.contains(sample.date) }) else { return false }

                    guard !activityByMinute.isEmpty else { return true }
                    let minute = Int(sample.date.timeIntervalSince1970 / 60)
                    let movement = activityByMinute[minute] ?? activityByMinute[minute - 1]
                    return movement.map { $0 < stillThreshold } ?? false
                }
                .map { $0.value }
                .sorted()

                guard restingSamples.count >= minimumSamples else { return nil }
                return RestingHeartRateDay(date: day, bpm: restingSamples[restingSamples.count / 10])
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    // Today's averages
    // Last night's sleep counted even if it started yesterday
    func heartRateAverages(deviceId: String, activeWorkoutStart: Date?, completion: @escaping (HeartRateAverages) -> Void) {
        let start = Calendar.current.startOfDay(for: Date())

        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let now = Date()
            let sleep = self.sleepIntervals(in: DateInterval(start: start, end: now), deviceId: deviceId, context: context)

            let request: NSFetchRequest<UserExercise> = UserExercise.fetchRequest()
            request.predicate = NSPredicate(format: "deviceId == %@ AND endDate >= %@", deviceId, start as NSDate)
            let workouts = ((try? context.fetch(request)) ?? []).compactMap { workout -> DateInterval? in
                guard let start = workout.startDate, let end = workout.endDate, end > start else { return nil }
                return DateInterval(start: start, end: end)
            } + [activeWorkoutStart.map { DateInterval(start: $0, end: now) }].compactMap { $0 }

            let fetchStart = sleep.map { $0.start }.min().map { Swift.min($0, start) } ?? start
            let samples = self.points(HeartDataPoint.self, in: DateInterval(start: fetchStart, end: now), deviceId: deviceId, context: context).compactMap { point -> (date: Date, value: Double)? in
                guard let timestamp = point.timestamp, point.value > 0 else { return nil }
                return (timestamp, point.value)
            }

            let isAsleep = { (date: Date) in sleep.contains { $0.contains(date) } }
            let isWorkingOut = { (date: Date) in workouts.contains { $0.contains(date) } }
            let average = { (values: [Double]) -> Double? in
                values.count >= self.minimumSamples ? values.reduce(0, +) / Double(values.count) : nil
            }

            let averages = HeartRateAverages(
                awake: average(samples.filter { $0.date >= start && !isAsleep($0.date) && !isWorkingOut($0.date) }.map { $0.value }),
                sleep: average(samples.filter { isAsleep($0.date) }.map { $0.value }),
                workout: average(samples.filter { $0.date >= start && isWorkingOut($0.date) }.map { $0.value })
            )

            DispatchQueue.main.async {
                completion(averages)
            }
        }
    }

    // Today counts even if the goal isn't hit yet
    func stepGoalStreak(deviceId: String, goal: Int, completion: @escaping (Int) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard goal > 0, let start = calendar.date(byAdding: .day, value: -364, to: today) else { return }

        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
            request.predicate = NSPredicate(format: "deviceId == %@ AND timestamp >= %@", deviceId, start as NSDate)

            var stepsByDay = [Date: Int]()
            for record in (try? context.fetch(request)) ?? [] {
                guard let timestamp = record.timestamp else { continue }
                stepsByDay[calendar.startOfDay(for: timestamp), default: 0] += Int(record.steps)
            }

            var streak = 0
            var day = (stepsByDay[today] ?? 0) >= goal ? today : calendar.date(byAdding: .day, value: -1, to: today) ?? today
            while (stepsByDay[day] ?? 0) >= goal, day >= start {
                streak += 1
                day = calendar.date(byAdding: .day, value: -1, to: day) ?? start
            }

            DispatchQueue.main.async {
                completion(streak)
            }
        }
    }

    private func points<T: NSManagedObject>(_ type: T.Type, in range: DateInterval, deviceId: String, context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@", deviceId, range.start as NSDate, range.end as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    private func sleepIntervals(in range: DateInterval, deviceId: String, context: NSManagedObjectContext) -> [DateInterval] {
        let request: NSFetchRequest<SleepSession> = SleepSession.fetchRequest()
        // Include the night before so the first morning has its sleep
        request.predicate = NSPredicate(format: "deviceId == %@ AND end >= %@", deviceId, range.start as NSDate)

        return ((try? context.fetch(request)) ?? []).compactMap { session in
            guard let start = session.start, let end = session.end, end > start else { return nil }
            return DateInterval(start: start, end: end)
        }
    }
}
