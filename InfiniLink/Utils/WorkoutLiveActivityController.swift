//
//  WorkoutLiveActivityController.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/9/26.
//

import Foundation
import ActivityKit
import UIKit

@available(iOS 16.2, *)
final class WorkoutLiveActivityController {
    private var activity: Activity<WorkoutAttributes>?
    private let staleAfter: TimeInterval = 60

    func start(name: String, icon: String, state: WorkoutAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // An earlier workout's activity can outlive the app if it gets quit, etc.
        // adopt it and kill any extras instances instead of stacking another one on the lock screen
        let running = Activity<WorkoutAttributes>.activities
        if let existing = running.first {
            activity = existing
            for extra in running.dropFirst() {
                Task { await extra.end(nil, dismissalPolicy: .immediate) }
            }
            update(state)
            return
        }

        let attributes = WorkoutAttributes(exerciseName: name, exerciseIcon: icon)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: Date().addingTimeInterval(staleAfter)),
                pushType: nil
            )
        } catch {
            log("Failed to start workout Live Activity: \(error.localizedDescription)", caller: "WorkoutLiveActivityController")
        }
    }

    func update(_ state: WorkoutAttributes.ContentState) {
        guard let activity else { return }

        // Without this, a BLE background wake can let iOS suspend the app again before the update reaches the widget, so schedule a background task to keep it alive
        Task { @MainActor in
            let task = UIApplication.shared.beginBackgroundTask()
            defer { UIApplication.shared.endBackgroundTask(task) }

            await activity.update(.init(state: state, staleDate: Date().addingTimeInterval(staleAfter)))
        }
    }

    func end() {
        activity = nil

        let running = Activity<WorkoutAttributes>.activities
        guard !running.isEmpty else { return }

        Task {
            for activity in running {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
