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
    
    @State private var searchText = ""
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
    private let persistenceController = PersistenceController.shared
    
    private var filteredExercises: [UserExercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return exerciseViewModel.userExercises
        }
        return exerciseViewModel.userExercises.filter {
            guard let startDate = $0.startDate, let exercise = exerciseViewModel.exercises.first(where: { $0.id == $0.id }) else { return false }
            
            return exercise.name.lowercased().contains(query) || startDate.formatted().lowercased().contains(query)
        }
    }
    
    private func updateUserExercises() {
        exerciseViewModel.userExercises = chartManager.userExercises()
    }
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let userExercise = chartManager.userExercises()[index]
            viewContext.delete(userExercise)
        }
        
        persistenceController.save()
        updateUserExercises()
        
        if exerciseViewModel.userExercises.isEmpty {
            dismiss()
        }
    }
    
    var body: some View {
        List {
            Section {
                if filteredExercises.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Nothing matched your search. Ensure your spelling is correct and try again.")
                } else {
                    ForEach(filteredExercises.sorted(by: { $0.startDate ?? Date() > $1.startDate ?? Date() })) { userExercise in
                        if let exercise = exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId }) {
                            NavigationLink {
                                ExerciseDetailView(userExercise: userExercise)
                            } label: {
                                HStack {
                                    Image(systemName: exercise.icon)
                                        .font(.system(size: 24).weight(.medium))
                                        .frame(minWidth: 40)
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
                .disabled(exerciseViewModel.userExercises.isEmpty)
        }
        .onAppear {
            updateUserExercises()
        }
    }
}
