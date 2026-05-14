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
    var pinLabel: some View {
        Label(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash" : "pin")
    }
    
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
                exerciseViewModel.setExercisePinned(exercise)
            } label: {
                pinLabel
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
