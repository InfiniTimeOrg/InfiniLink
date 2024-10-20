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
    @State var exerciseToStart: Exercise?
    
    @Environment(\.managedObjectContext) var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \UserExercise.startDate, ascending: false)]) var userExercises: FetchedResults<UserExercise>
    
    var body: some View {
        VStack {
            if exerciseToStart != nil {
                ActiveExerciseView(exercise: $exerciseToStart)
            } else {
                List {
                    Section("My Exercises") {
                        if userExercises.isEmpty {
                            Text("No Exercises. Start a new one by clicking on one below.")
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
                                exerciseToStart = exercise
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
