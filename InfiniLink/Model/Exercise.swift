//
//  Exercise.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import HealthKit

enum ExerciseComponents {
    case heart
    case steps
    case location
}

struct WorkoutSession: Codable, Equatable, Identifiable {
    let id: UUID
    let exerciseId: String
    let startDate: Date

    var pausedIntervals: [DateInterval]
    var pauseStartedAt: Date?

    var lastWatchStepCount: Int?
    var accumulatedSteps: Int
    var routePoints: [RoutePoint]

    var heartRateSum: Double
    var heartRateSampleCount: Int
    var maxHeartRate: Double

    var lastHeartbeat: Date

    init(exerciseId: String, startDate: Date = Date()) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.startDate = startDate
        self.pausedIntervals = []
        self.pauseStartedAt = nil
        self.lastWatchStepCount = nil
        self.accumulatedSteps = 0
        self.routePoints = []
        self.heartRateSum = 0
        self.heartRateSampleCount = 0
        self.maxHeartRate = 0
        self.lastHeartbeat = startDate
    }

    var averageHeartRate: Double {
        return heartRateSampleCount > 0 ? heartRateSum / Double(heartRateSampleCount) : 0
    }

    var isPaused: Bool {
        return pauseStartedAt != nil
    }

    func elapsed(at date: Date = Date()) -> TimeInterval {
        let gross = date.timeIntervalSince(startDate)
        let completedPauses = pausedIntervals.reduce(0) { $0 + $1.duration }
        let currentPause = pauseStartedAt.map { date.timeIntervalSince($0) } ?? 0

        return max(0, gross - completedPauses - currentPause)
    }
}

struct WorkoutSessionStore {
    private static let fileName = "active-workout.json"

    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?.appendingPathComponent(fileName)
    }

    static func load() -> WorkoutSession? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }

        return try? JSONDecoder().decode(WorkoutSession.self, from: data)
    }

    static func save(_ session: WorkoutSession) {
        guard let fileURL, let data = try? JSONEncoder().encode(session) else { return }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log("Failed to persist workout session: \(error.localizedDescription)", caller: "WorkoutSessionStore")
        }
    }

    static func clear() {
        guard let fileURL else { return }

        try? FileManager.default.removeItem(at: fileURL)
    }
}

struct Exercise: Identifiable {
    let id: String
    var name: String
    var icon: String
    let components: [ExerciseComponents]
    let pace: Pace
    let activityType: HKWorkoutActivityType
    
    init(id: String, name: String, icon: String, components: [ExerciseComponents], pace: Pace = .avgWalk, activityType: HKWorkoutActivityType = .running) {
        self.id = id
        self.name = name
        self.icon = icon
        self.components = components
        self.pace = pace
        self.activityType = activityType
    }
}
