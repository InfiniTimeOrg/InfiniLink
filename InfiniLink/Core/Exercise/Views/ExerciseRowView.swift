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
    let onStart: (() -> Void)?
    var pinLabel: some View {
        Label(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash" : "pin")
    }
    
    init(_ exercise: Exercise, pinned: Bool = false, onStart: (() -> Void)? = nil) {
        self.exercise = exercise
        self.pinned = pinned
        self.onStart = onStart
    }
    
    var body: some View {
        Button {
            exerciseViewModel.startExercise(exercise)
            onStart?()
        } label: {
            Label(exercise.name, systemImage: exercise.icon)
        }
        .disabled(!bleManager.hasLoadedCharacteristics)
        .contextMenu {
            Button {
                exerciseViewModel.setExercisePinned(exercise)
            } label: {
                pinLabel
            }
            if exercise.isCustom {
                Button(role: .destructive) {
                    exerciseViewModel.deleteCustomExercise(exercise)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                exerciseViewModel.setExercisePinned(exercise)
            } label: {
                pinLabel
            }
            .tint(.yellow)
        }
    }
}
