//
//  ExerciseRowView.swift
//  InfiniLink
//
//  Created by Liam Willey on 6/5/25.
//

import SwiftUI

struct ExerciseRowView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    let exercise: Exercise
    let pinned: Bool
    
    init(_ exercise: Exercise, pinned: Bool = false) {
        self.exercise = exercise
        self.pinned = pinned
    }
    
    var body: some View {
        Button {
            exerciseViewModel.startExercise(exercise)
        } label: {
            Label(exercise.name, systemImage: exercise.icon)
        }
        .disabled(!bleManager.hasLoadedCharacteristics)
        .contextMenu {
            Button {
                if pinned {
                    exerciseViewModel.pinnedExercises.removeAll(where: { $0 == exercise.id })
                } else {
                    exerciseViewModel.pinnedExercises.append(exercise.id)
                }
                exerciseViewModel.setPinnedExercises()
            } label: {
                Label(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash" : "pin")
            }
        }
    }
}
