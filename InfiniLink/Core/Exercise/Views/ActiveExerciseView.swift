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
    @ObservedObject var musicController = MusicController.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @Binding var exercise: Exercise?
    
    @State private var timer: Timer?
    @State private var showEndConfirmation = false
    
    @State private var previousHeartPoints: [HeartDataPoint] = []
    @State private var newHeartPoints: [HeartDataPoint] = []
    @State private var currentStepCount = 0
    
    var body: some View {
        if let exercise {
            VStack(spacing: 16) {
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
                            Text(String(exerciseViewModel.stepsTaken))
                        }
                    }
                }
                Spacer()
                if musicController.musicPlaying != 0 {
                    HStack(spacing: 12) {
                        if let artwork = musicController.musicPlayer.nowPlayingItem?.artwork, let image = artwork.image(at: CGSize(width: 52, height: 52)) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(musicController.musicPlayer.nowPlayingItem?.title ?? "Not Playing")
                                .fontWeight(.bold)
                            if let artist = musicController.musicPlayer.nowPlayingItem?.artist {
                                Text(artist)
                            }
                        }
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                musicController.musicPlaying == 1 ? musicController.pause() : musicController.play()
                            } label: {
                                Image(systemName: musicController.musicPlaying == 1 ? "pause.fill" : "play.fill")
                                    .font(.system(size: 21))
                            }
                            Button {
                                musicController.skipForward()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 22))
                            }
                        }
                    }
                    .padding(14)
                    .foregroundStyle(Color.primary)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
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
                currentStepCount = bleManager.stepCount
                DispatchQueue.main.async {
                    startTimer()
                    musicController.updateMusicInformation()
                }
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
