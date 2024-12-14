//
//  ExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData

struct ExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \UserExercise.startDate, ascending: false)]) var userExercises: FetchedResults<UserExercise>
    
    var body: some View {
        VStack {
            if exerciseViewModel.currentExercise != nil {
                ActiveExerciseView(exercise: $exerciseViewModel.currentExercise)
            } else {
                List {
                    Section(header: Text("My Exercises"), footer: Text(userExercises.isEmpty ? "You can start one by choosing one from the list below." : "")) {
                        if userExercises.isEmpty {
                            Text("No Exercises")
                        } else {
                            ForEach(userExercises) { userExercise in
                                let exercise = exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId })!

                                NavigationLink {
                                    ExerciseDetailView(userExercise: userExercise)
                                } label: {
                                    HStack {
                                        Image(systemName: exercise.icon)
                                            .font(.system(size: 24).weight(.medium))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.body.weight(.medium))
                                            Text(userExercise.startDate!.formatted())
                                                .foregroundStyle(Color.gray)
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    Section("All Exercises") {
                        ForEach(exerciseViewModel.exercises) { exercise in
                            Button {
                                exerciseViewModel.startExercise(exercise)
                            } label: {
                                Label(exercise.name, systemImage: exercise.icon)
                            }
                        }
                    }
                }
                .navigationTitle("Exercise")
                .toolbar {
                    EditButton()
                        .disabled(userExercises.isEmpty)
                }
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let userExercise = userExercises[index]
            viewContext.delete(userExercise)
        }
        
        exerciseViewModel.saveContext(viewContext)
    }
}

#Preview {
    NavigationView {
        ExerciseView()
    }
}
