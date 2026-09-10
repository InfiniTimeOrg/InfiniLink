//
//  ActiveExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ActiveExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var routeRecorder = WorkoutRouteRecorder.shared

    @Environment(\.dismiss) private var dismiss

    @State private var showEndConfirmation = false

    private let fitnessCalculator = FitnessCalculator()

    private var canSave: Bool {
        return exerciseViewModel.elapsed >= 30
    }

    @ViewBuilder
    private func metric(_ icon: String, _ tint: Color, _ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if let exercise = exerciseViewModel.currentExercise {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: exercise.icon)
                    Text(exercise.name)
                }
                .font(.title2.weight(.medium))
                Text(exerciseViewModel.timeString())
                    .font(.system(size: 60).weight(.bold))
                    .monospacedDigit()
                Grid(horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        if exercise.components.contains(.heart) {
                            metric("heart.fill", .red, String(format: "%.0f", bleManager.heartRate), "BPM")
                        }
                        metric("flame.fill", .orange, "\(fitnessCalculator.energyValue(kcal: Double(exerciseViewModel.liveCalorieEstimate(for: exercise))))", fitnessCalculator.energyUnitLabel(short: true).uppercased())
                        if exercise.components.contains(.steps) {
                            metric("shoeprints.fill", .blue, "\(exerciseViewModel.stepsTaken)", "STEPS")
                        }
                        if exercise.components.contains(.location) {
                            metric("location.fill", .green, fitnessCalculator.distanceString(meters: routeRecorder.distance), "DIST")
                        }
                    }
                    if exercise.components.contains(.heart) && exerciseViewModel.averageHeartRate > 0 {
                        GridRow {
                            metric("heart", .red.opacity(0.7), String(format: "%.0f", exerciseViewModel.averageHeartRate), "AVG")
                            metric("bolt.heart", .red.opacity(0.7), String(format: "%.0f", exerciseViewModel.maxHeartRate), "MAX")
                        }
                    }
                }
                if exerciseViewModel.exercisePaused {
                    Text(exerciseViewModel.autoPaused ? "Auto-Paused" : "Paused")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                Spacer()
                HStack(spacing: 14) {
                    Spacer()
                    Button {
                        if exerciseViewModel.exercisePaused {
                            exerciseViewModel.resumeExercise()
                        } else {
                            exerciseViewModel.pauseExercise()
                        }
                    } label: {
                        Image(systemName: exerciseViewModel.exercisePaused ? "play.fill" : "pause.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(15)
                            .padding(.leading, exerciseViewModel.exercisePaused ? 2 : 0) // Offset play icon a little to the right because it doesn't look centered to the eye
                            .frame(width: 45, height: 45)
                            .background(Material.regular)
                            .foregroundStyle(exerciseViewModel.exercisePaused ? Color.white : Color.primary)
                            .clipShape(Circle())
                    }
                    Button {
                        showEndConfirmation = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 25))
                            .padding(25)
                            .background(Color.red)
                            .foregroundStyle(Color.white)
                            .clipShape(Circle())
                    }
                    Color.clear // This centers the other elements
                        .frame(width: 45, height: 45)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
        .alert(canSave ? "Are you sure you want to end the exercise?" : "Are you sure you want to end the exercise? The duration of the exercise is too short to save.", isPresented: $showEndConfirmation) {
            Button(role: .destructive) {
                exerciseViewModel.endExercise(save: canSave)
            } label: {
                Text("End Exercise")
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: exerciseViewModel.currentExercise?.id) { id in
            if id == nil {
                dismiss()
            }
        }
    }
}
