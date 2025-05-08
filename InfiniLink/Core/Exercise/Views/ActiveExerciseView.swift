//
//  ActiveExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ActiveExerciseView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var stepCounts: FetchedResults<StepCounts>
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var showEndConfirmation = false
    
    @State private var previousHeartPoints: [HeartDataPoint] = []
    @State private var newHeartPoints: [HeartDataPoint] = []
    @State private var currentStepCount = 0
    
    private let fitnessCalculator = FitnessCalculator()
    
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
                HStack(spacing: 30) {
                    if exercise.components.contains(.heart) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text(String(format: "%.0f", previousHeartPoints.compactMap({ $0.value }).last ?? 0))
                        }
                    }
                    if exercise.components.contains(.steps) {
                        HStack(spacing: 6) {
                            Image(systemName: "shoeprints.fill")
                                .foregroundStyle(.blue)
                            Text(String(exerciseViewModel.stepsTaken))
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(fitnessCalculator.calculateCaloriesBurned(steps: exerciseViewModel.stepsTaken))")
                        }
                    }
                }
                Spacer()
                HStack(spacing: 14) {
                    Spacer()
                    Button {
                        if exerciseViewModel.exercisePaused {
                            exerciseViewModel.startTimer()
                        } else {
                            exerciseViewModel.timer?.invalidate()
                            exerciseViewModel.timer = nil
                        }
                        exerciseViewModel.exercisePaused.toggle()
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
                    // This centers the other elements
                    Color.clear
                        .frame(width: 45, height: 45)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
        .alert("Are you sure you want to end the exercise? \(exerciseViewModel.exerciseTime >= 30 ? "" : "The duration of the exercise is too short to save.")", isPresented: $showEndConfirmation) {
            Button(role: .destructive) {
                guard let exercise = exerciseViewModel.currentExercise else { return }
                
                if exerciseViewModel.exerciseTime >= 30 {
                    exerciseViewModel.saveExercise(exercise, startDate: Date().addingTimeInterval(-exerciseViewModel.exerciseTime), heartPoints: Array(heartPoints))
                }
                
                exerciseViewModel.currentExercise = nil
                exerciseViewModel.timer?.invalidate()
            } label: {
                Text("End Exercise")
            }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            currentStepCount = bleManager.stepCount
        }
        // Should these onChanges go in BLECharacteristicHandler?
        .onChange(of: Array(heartPoints)) { newPoints in
            let currentHeartPoints = Array(newPoints)
            
            newHeartPoints = currentHeartPoints.filter { !previousHeartPoints.contains($0) }
            previousHeartPoints = currentHeartPoints
        }
        .onChange(of: bleManager.stepCount) { allSteps in
            let steps = max(0, allSteps - currentStepCount)
            
            exerciseViewModel.stepsTaken = steps
        }
    }
}

#Preview {
    ActiveExerciseView()
}
