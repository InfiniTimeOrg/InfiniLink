//
//  ActiveExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ActiveExerciseView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \StepCounts.timestamp, ascending: true)])
    private var stepCounts: FetchedResults<StepCounts>
    
    @Environment(\.managedObjectContext) var viewContext
    
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    @Binding var exercise: Exercise?
    
    @State private var timer: Timer?
    @State private var showEndConfirmation = false
    
    @State private var previousHeartPoints: [HeartDataPoint] = []
    @State private var newHeartPoints: [HeartDataPoint] = []
    @State private var previousStepCounts: [StepCounts] = []
    @State private var newStepCounts: [StepCounts] = []
    
    var body: some View {
        if let exercise {
            VStack {
                HStack(spacing: 6) {
                    Image(systemName: exercise.icon)
                    Text(exercise.name)
                }
                Spacer()
                Text(exerciseViewModel.timeString())
                    .font(.system(size: 60).weight(.bold))
                HStack {
                    if exercise.components.contains(.heart) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text(String(format: "%.0f", previousHeartPoints.compactMap({ $0.value }).last ?? 0))
                        }
                    }
                    Spacer()
                        .frame(maxWidth: 30)
                    if exercise.components.contains(.steps) {
                        HStack(spacing: 6) {
                            Image(systemName: "shoeprints.fill")
                                .foregroundStyle(.blue)
                            Text(String(format: "%.0f", newStepCounts.compactMap({ $0.steps }).last ?? 0))
                        }
                    }
                }
                Spacer()
                HStack(spacing: 14) {
                    Spacer()
                    Button {
                        if exerciseViewModel.exercisePaused {
                            startTimer()
                        } else {
                            timer?.invalidate()
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
                    Color.clear
                        .frame(width: 45, height: 45)
                    Spacer()
                }
            }
            .padding()
            .alert("Are you sure you want to end the exercise? \(exerciseViewModel.exerciseTime >= 30 ? "" : "The duration of the exercise is too short to save.")", isPresented: $showEndConfirmation) {
                Button(role: .destructive) {
                    self.exercise = nil
                    timer?.invalidate()
                    
                    if exerciseViewModel.exerciseTime >= 30 {
                        exerciseViewModel.saveExercise(exercise.id, startDate: Date().addingTimeInterval(-exerciseViewModel.exerciseTime), heartPoints: Array(heartPoints), viewContext: viewContext)
                    }
                } label: {
                    Text("End Exercise")
                }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear {
                startTimer()
            }
            .onChange(of: Array(heartPoints)) { newPoints in
                let currentHeartPoints = Array(newPoints)
                
                newHeartPoints = currentHeartPoints.filter { !previousHeartPoints.contains($0) }
                previousHeartPoints = currentHeartPoints
            }
            .onChange(of: Array(stepCounts)) { newPoints in
                let currentStepCounts = Array(newPoints)
                
                newStepCounts = currentStepCounts.filter { !previousStepCounts.contains($0) }
                previousStepCounts = currentStepCounts
            }
            .navigationBarHidden(true)
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            exerciseViewModel.exerciseTime += 1
        }
    }
}

#Preview {
    ActiveExerciseView(exercise: .constant(Exercise(id: "volleyball", name: "Volleyball", icon: "figure.volleyball", components: [.steps, .heart])))
}
