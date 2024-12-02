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
    
    func timeDifferenceFormatted(startDate: Date, endDate: Date) -> String {
        let difference = endDate.timeIntervalSince(startDate)
        let totalSeconds = Int(difference)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        print(difference)
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
        }
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
                        Group {
                            Text(userExercise.startDate!.formatted())
                            Text(timeDifferenceFormatted(startDate: userExercise.startDate!, endDate: userExercise.endDate!))
                        }
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
