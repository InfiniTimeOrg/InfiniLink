//
//  ExerciseDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ExerciseDetailView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    let userExercise: UserExercise
    
    func exercise() -> Exercise {
        return exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId ?? "" })!
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 7) {
                    Image(systemName: exercise().icon)
                        .font(.system(size: 50).weight(.medium))
                    VStack(spacing: 4) {
                        Text(exercise().name)
                            .font(.largeTitle.weight(.bold))
                        Text(userExercise.startDate!.formatted())
                            .foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            Section {
                // TODO: add heart range
                // TODO: add steps
            }
        }
    }
}

#Preview {
    ExerciseDetailView(userExercise: {
        let exercise = UserExercise()
        
        exercise.endDate = Date()
        exercise.startDate = Date.distantPast
        exercise.exerciseId = "outdoor-run"
        exercise.heartPoints = []
        
        return exercise
    }())
}
