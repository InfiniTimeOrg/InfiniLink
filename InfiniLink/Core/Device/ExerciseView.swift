//
//  ExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct UserExercise: Identifiable {
    let id = UUID()
    var exercise: String
    var startDate: Date
    var endDate: Date
}

struct Exercise: Identifiable {
    let id: String
    var name: String
    var icon: String
}

struct ExerciseView: View {
    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run"),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle"),
        Exercise(id: "indoor-run", name: "Outdoor Run", icon: "figure.run.treadmill"),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle"),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis"),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis"),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer"),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball"),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton")
    ]
    let dummyExercises = [
        UserExercise(exercise: "table-tennis", startDate: Date.distantPast, endDate: Date.now)
    ]
    
    var body: some View {
        List {
            Section("My Exercises") {
                if dummyExercises.isEmpty {
                    Text("No Exercises")
                } else {
                    ForEach(dummyExercises) { userExercise in
                        let exercise = exercises.first(where: { $0.id == userExercise.exercise})!
                        
                        NavigationLink {
                            
                        } label: {
                            HStack {
                                Image(systemName: exercise.icon)
                                    .font(.system(size: 24).weight(.medium))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.body.weight(.medium))
                                    Text(userExercise.startDate.formatted() + " — " + userExercise.endDate.formatted())
                                        .foregroundStyle(Color.gray)
                                }
                            }
                        }
                    }
                }
            }
            Section("All Exercises") {
                ForEach(exercises) { exercise in
                    Label(exercise.name, systemImage: exercise.icon)
                }
            }
        }
        .navigationTitle("Exercise")
        .toolbar {
            Button {
                
            } label: {
                Label("Start Exercise", systemImage: "plus")
            }
        }
    }
}

#Preview {
    NavigationView {
        ExerciseView()
    }
}
