//
//  ExerciseDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ExerciseDetailView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartDataPoints: FetchedResults<HeartDataPoint>
    
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    let userExercise: UserExercise
    
    var heartPoints: [HeartDataPoint] {
        return heartDataPoints.filter({
            guard let timestamp = $0.timestamp else { return false }
            guard let startDate = userExercise.startDate else { return false }
            guard let endDate = userExercise.endDate else { return false }
            
            return startDate <= timestamp && timestamp <= endDate
        })
    }
    
    func exercise() -> Exercise {
        return exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId ?? "" })!
    }
    
    func timeDifferenceFormatted(startDate: Date, endDate: Date) -> String {
        let difference = endDate.timeIntervalSince(startDate)
        let totalSeconds = Int(difference)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") and \(seconds) second\(seconds == 1 ? "" : "s")"
        } else {
            return "\(seconds) second\(seconds == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        GeometryReader { geo in
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
                Section("Time") {
                    let startDate = userExercise.startDate!
                    
                    Text("Starting on \(startDate.formatted(.dateTime.day().month())) at \(startDate.formatted(.dateTime.hour().minute())), the exercise lasted \(timeDifferenceFormatted(startDate: startDate, endDate: userExercise.endDate!)).")
                }
                Section("Heart Rate") {
                    let heartValues = heartPoints.compactMap({ $0.value })
                    let min = Int(heartValues.min() ?? 0)
                    let max = Int(heartValues.max() ?? 0)
                    
                    if heartPoints.count > 1 {
                        Text("Averaging at \(String(format: "%.0f", Double(heartValues.reduce(0, +)) / Double(heartValues.count))) BPM, your heart rate ranged from \(min) to \(max) BPM.")
                    } else {
                        Text("There wasn't any heart rate data recorded for this exercise.")
                    }
                }
                if exercise().components.contains(.steps) {
                    Section("Steps") {
                        let calories = FitnessCalculator().calculateCaloriesBurned(steps: Int(userExercise.steps))
                        
                        Text("You took \(userExercise.steps) step\(userExercise.steps == 1 ? "" : "s") and burned \(calories > 1 ? String(format: "%.0f", calories) + "calories": "less than one calorie").")
                    }
                }
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
