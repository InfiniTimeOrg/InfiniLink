//
//  AllExercisesView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/7/25.
//

import SwiftUI

struct AllExercisesView: View {
    @ObservedObject private var chartManager = ChartManager.shared
    @ObservedObject private var exerciseViewModel = ExerciseViewModel.shared
    
    @State private var userExercises = [UserExercise]()
    @State private var searchText = ""
    
    @Environment(\.managedObjectContext) var viewContext
    
    private var filteredExercises: [UserExercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return userExercises
        }
        return userExercises.filter {
            guard let startDate = $0.startDate, let exercise = exerciseViewModel.exercises.first(where: { $0.id == $0.id }) else { return false }
            
            return exercise.name.lowercased().contains(query) || startDate.formatted().lowercased().contains(query)
        }
    }
    
    private func updateUserExercises() {
        userExercises = chartManager.userExercises()
    }
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let userExercise = chartManager.userExercises()[index]
            viewContext.delete(userExercise)
        }
        
        PersistenceController.shared.save()
    }
    
    var body: some View {
        List {
            Section {
                if userExercises.isEmpty {
                    Text("You don't have any saved exercises. When you complete one, they'll show up here.")
                } else {
                    ForEach(filteredExercises.sorted(by: { $0.startDate ?? Date() > $1.startDate ?? Date() })) { userExercise in
                        if let exercise = exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId }) {
                            NavigationLink {
                                ExerciseDetailView(userExercise: userExercise)
                            } label: {
                                HStack {
                                    Image(systemName: exercise.icon)
                                        .font(.system(size: 24).weight(.medium))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.body.weight(.medium))
                                        Text(userExercise.startDate?.formatted() ?? "Unknown date")
                                            .foregroundStyle(Color.gray)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("My Exercises")
        .searchable(text: $searchText, prompt: "Search by name or date")
        .toolbar {
            EditButton()
                .disabled(userExercises.isEmpty)
        }
        .onAppear {
            updateUserExercises()
        }
    }
}

#Preview {
    AllExercisesView()
}
