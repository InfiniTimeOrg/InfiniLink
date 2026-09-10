//
//  WorkoutShared.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/9/26.
//

import Foundation
import ActivityKit
import AppIntents

struct WorkoutAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var effectiveStart: Date
        var pausedAt: Date?
        var heartRate: Int
        var steps: Int
        var calories: Int
        var distanceMeters: Double
        var showsSteps: Bool
        var showsDistance: Bool
        var usesImperial: Bool
        var usesKilojoules: Bool
    }

    var exerciseName: String
    var exerciseIcon: String
}

enum WorkoutLiveActivityCommand: String {
    case pause
    case resume
    case end
}

extension Foundation.Notification.Name {
    static let workoutLiveActivityCommand = Foundation.Notification.Name("workoutLiveActivityCommand")
}

enum AppGroup {
    static let identifier = "group.com.alexemry.Infini-iOS"
}

enum WorkoutCommandBox {
    private static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?.appendingPathComponent("workout-command")
    }

    static func write(_ command: WorkoutLiveActivityCommand) {
        guard let url else { return }

        try? Data(command.rawValue.utf8).write(to: url, options: .atomic)
        NotificationCenter.default.post(name: .workoutLiveActivityCommand, object: nil)
    }

    static func take() -> WorkoutLiveActivityCommand? {
        guard let url, let data = try? Data(contentsOf: url), let raw = String(data: data, encoding: .utf8) else { return nil }

        try? FileManager.default.removeItem(at: url)
        return WorkoutLiveActivityCommand(rawValue: raw)
    }
}

@available(iOS 17.0, *)
struct PauseWorkoutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause Workout"

    func perform() async throws -> some IntentResult {
        WorkoutCommandBox.write(.pause)
        return .result()
    }
}

@available(iOS 17.0, *)
struct ResumeWorkoutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume Workout"

    func perform() async throws -> some IntentResult {
        WorkoutCommandBox.write(.resume)
        return .result()
    }
}

@available(iOS 17.0, *)
struct EndWorkoutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Workout"

    func perform() async throws -> some IntentResult {
        WorkoutCommandBox.write(.end)

        for activity in Activity<WorkoutAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
