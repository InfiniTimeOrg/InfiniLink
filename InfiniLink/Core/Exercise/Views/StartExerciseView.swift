//
//  StartExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct StartExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared

    @Environment(\.dismiss) var dismiss

    @State private var showCustomExerciseSheet = false

    var body: some View {
        NavigationStack {
            List {
                if !bleManager.hasLoadedCharacteristics {
                    Section {
                        Text(DeviceManager.shared.name + " needs to be connected before you can start an exercise.")
                    }
                }
                if !exerciseViewModel.pinnedExerciseIds.isEmpty {
                    Section("Pinned") {
                        let exerciseMap = Dictionary(uniqueKeysWithValues: exerciseViewModel.exercises.map { ($0.id, $0) })
                        ForEach(exerciseViewModel.pinnedExerciseIds.compactMap { exerciseMap[$0] }) { exercise in
                            ExerciseRowView(exercise, pinned: true) {
                                dismiss()
                            }
                        }
                    }
                }
                Section {
                    ForEach(exerciseViewModel.exercises.filter({ !exerciseViewModel.pinnedExerciseIds.contains($0.id) }), id: \.id) { exercise in
                        ExerciseRowView(exercise) {
                            dismiss()
                        }
                    }
                } header: {
                    Text("All Exercises")
                } footer: {
                    Text("You can pin an exercise by long pressing the exercise you want to pin.")
                }
                Section {
                    Button {
                        showCustomExerciseSheet = true
                    } label: {
                        Label("New Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Start Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCustomExerciseSheet) {
                CustomExerciseView()
            }
        }
    }
}

#Preview {
    StartExerciseView()
}
