//
//  ExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData

struct ExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        VStack {
            if exerciseViewModel.currentExercise != nil {
                ActiveExerciseView()
            } else {
                List {
                    if !bleManager.hasLoadedCharacteristics {
                        Section {
                            Text(DeviceManager.shared.name + " needs to be connected before you can start an exercise.")
                        }
                    }
                    if bleManager.hasLoadedCharacteristics || !exerciseViewModel.userExercises.isEmpty {
                        if !exerciseViewModel.userExercises.isEmpty {
                            NavigationLink {
                                AllExercisesView()
                            } label: {
                                Text("My Exercises")
                            }
                        } else {
                            Text("You don't have any saved exercises. You can start a new exercise by choosing one from the list below.")
                        }
                    }
                    if !exerciseViewModel.pinnedExerciseIds.isEmpty {
                        Section("Pinned") {
                            let exerciseMap = Dictionary(uniqueKeysWithValues: exerciseViewModel.exercises.map { ($0.id, $0) })
                            ForEach(exerciseViewModel.pinnedExerciseIds.compactMap { exerciseMap[$0] }) { exercise in
                                ExerciseRowView(exercise, pinned: true)
                            }
                        }
                    }
                    Section {
                        ForEach(exerciseViewModel.exercises.filter({ !exerciseViewModel.pinnedExerciseIds.contains($0.id) }), id: \.id) { exercise in
                            ExerciseRowView(exercise)
                        }
                    } header: {
                        Text("All Exercises")
                    } footer: {
                        Text("You can pin an exercise by long pressing the exercise you want to pin.")
                    }
                }
                .navigationTitle("Exercise")
                .toolbar {
                    NavigationLink {
                        ExerciseSettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
        .onAppear {
            exerciseViewModel.userExercises = chartManager.userExercises()
        }
    }
}

struct RecoverExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared

    @State private var showConfirmation = false

    let session: WorkoutSession

    private var exerciseName: String {
        return exerciseViewModel.exercise(for: session.exerciseId)?.name ?? "Workout"
    }

    var body: some View {
        NavigationView {
            ActionView(Action(title: "Exercise in progress", subtitle: "Started \(session.startDate.formatted(.relative(presentation: .named))). Resume where you left off, save it as-is, or discard it.", icon: exerciseViewModel.exercise(for: session.exerciseId)?.icon ?? "figure.run", accent: .blue, buttons: [
                ActionButton("Resume", action: {
                    exerciseViewModel.resumeRecoveredSession()
                }),
                ActionButton("Save & End", role: .cancel, action: {
                    exerciseViewModel.saveAndEndRecoveredSession()
                }),
                ActionButton("Discard", role: .destructive, action: {
                    showConfirmation = true
                })
            ]))
            .interactiveDismissDisabled()
            .toolbar {
                Button(role: .cancel) {
                    showConfirmation = true
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
        }
        .confirmationDialog("Active Exercise", isPresented: $showConfirmation) {
            Button(role: .destructive) {
                exerciseViewModel.discardRecoveredSession()
            } label: {
                Text("Discard")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to discard the active exercise?")
        }
    }
}

#Preview {
    NavigationView {
        RecoverExerciseView(session: WorkoutSession(exerciseId: "test"))
    }
}
