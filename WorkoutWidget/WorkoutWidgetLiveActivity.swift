//
//  WorkoutWidgetLiveActivity.swift
//  WorkoutWidget
//
//  Created by Liam Willey on 9/9/26.
//

import ActivityKit
import AppIntents
import WidgetKit
import SwiftUI

private func timerText(_ state: WorkoutAttributes.ContentState) -> Text {
    Text(timerInterval: state.effectiveStart...state.effectiveStart.addingTimeInterval(24 * 60 * 60), pauseTime: state.pausedAt, countsDown: false)
}

private func distanceText(_ meters: Double, imperial: Bool) -> String {
    return imperial ? String(format: "%.2f mi", meters / 1609.344) : String(format: "%.2f km", meters / 1000)
}

private func energyText(_ kcal: Int, kilojoules: Bool) -> String {
    return kilojoules ? "\(Int((Double(kcal) * 4.184).rounded())) kJ" : "\(kcal)"
}

private func compactTimerWidth(_ state: WorkoutAttributes.ContentState) -> CGFloat {
    let reference = state.pausedAt ?? Date()
    return reference.timeIntervalSince(state.effectiveStart) >= 3600 ? 52 : 42
}

struct WorkoutMetricsRow: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            Label(String(state.heartRate), systemImage: "heart.fill")
                .foregroundStyle(.red)
            Label(energyText(state.calories, kilojoules: state.usesKilojoules), systemImage: "flame.fill")
                .foregroundStyle(.orange)
            if state.showsSteps {
                Label(String(state.steps), systemImage: "shoeprints.fill")
                    .foregroundStyle(.blue)
            }
            if state.showsDistance {
                Label(distanceText(state.distanceMeters, imperial: state.usesImperial), systemImage: "location.fill")
                    .foregroundStyle(.green)
            }
            Spacer()
        }
        .font(.subheadline)
        .lineLimit(1)
        .monospacedDigit()
    }
}

struct WorkoutControlButtons: View {
    let paused: Bool

    var body: some View {
        if #available(iOS 17.0, *) {
            HStack(spacing: 10) {
                if paused {
                    Button(intent: ResumeWorkoutIntent()) {
                        Label("Resume", systemImage: "play.fill")
                            .padding(4)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Button(intent: PauseWorkoutIntent()) {
                        Label("Pause", systemImage: "pause.fill")
                            .padding(4)
                            .frame(maxWidth: .infinity)
                    }
                }
                Button(intent: EndWorkoutIntent()) {
                    Label("End", systemImage: "stop.fill")
                        .padding(4)
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
            }
            .buttonStyle(.bordered)
            .fontWeight(.semibold)
        }
    }
}

struct WorkoutWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            VStack {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: context.attributes.exerciseIcon)
                            .font(.title3.bold())
                        Text(context.attributes.exerciseName)
                            .font(.title2.bold())
                        Spacer()
                        timerText(context.state)
                            .font(.title2.monospacedDigit().bold())
                            .multilineTextAlignment(.trailing)
                    }
                    WorkoutMetricsRow(state: context.state)
                }
                WorkoutControlButtons(paused: context.state.pausedAt != nil)
            }
            .padding()
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: context.attributes.exerciseIcon)
                                .font(.title3.bold())
                            Text(context.attributes.exerciseName)
                                .font(.title2.bold())
                            Spacer()
                            timerText(context.state)
                                .font(.title2.monospacedDigit().bold())
                                .multilineTextAlignment(.trailing)
                        }
                        WorkoutMetricsRow(state: context.state)
                    }
                    WorkoutControlButtons(paused: context.state.pausedAt != nil)
                }
            } compactLeading: {
                Image(systemName: context.attributes.exerciseIcon)
                    .foregroundStyle(.orange)
                    .padding(.leading, 3)
            } compactTrailing: {
                timerText(context.state)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: compactTimerWidth(context.state))
                    .foregroundStyle(.orange)
            } minimal: {
                Image(systemName: context.attributes.exerciseIcon)
                    .foregroundStyle(.orange)
            }
            .keylineTint(.orange)
        }
    }
}

extension WorkoutAttributes {
    fileprivate static var preview: WorkoutAttributes {
        WorkoutAttributes(exerciseName: "Outdoor Run", exerciseIcon: "figure.run")
    }
}

extension WorkoutAttributes.ContentState {
    fileprivate static var running: WorkoutAttributes.ContentState {
        WorkoutAttributes.ContentState(
            effectiveStart: Date().addingTimeInterval(-3590),
            pausedAt: nil,
            heartRate: 148,
            steps: 3120,
            calories: 212,
            distanceMeters: 3450,
            showsSteps: true,
            showsDistance: true,
            usesImperial: false,
            usesKilojoules: false
        )
    }

    fileprivate static var paused: WorkoutAttributes.ContentState {
        WorkoutAttributes.ContentState(
            effectiveStart: Date().addingTimeInterval(-1530),
            pausedAt: Date(),
            heartRate: 96,
            steps: 3120,
            calories: 212,
            distanceMeters: 3450,
            showsSteps: true,
            showsDistance: true,
            usesImperial: false,
            usesKilojoules: false
        )
    }
}

#Preview("Lock Screen", as: .content, using: WorkoutAttributes.preview) {
    WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.running
    WorkoutAttributes.ContentState.paused
}

#Preview("Dynamic Island (Expanded)", as: .dynamicIsland(.expanded), using: WorkoutAttributes.preview) {
    WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.running
    WorkoutAttributes.ContentState.paused
}

#Preview("Dynamic Island (Compact)", as: .dynamicIsland(.compact), using: WorkoutAttributes.preview) {
    WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.running
    WorkoutAttributes.ContentState.paused
}

#Preview("Dynamic Island (Minimal)", as: .dynamicIsland(.minimal), using: WorkoutAttributes.preview) {
    WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.running
    WorkoutAttributes.ContentState.paused
}
