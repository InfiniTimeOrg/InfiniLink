//
//  AllExercisesView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/7/25.
//

import SwiftUI
import CoreData

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
        return exerciseViewModel.userExercises.filter { userExercise in
            guard let startDate = userExercise.startDate, let exercise = exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId! }) else { return false }
            
            return exercise.name.lowercased().contains(query) || startDate.formatted().lowercased().contains(query)
        }
    }
    
    private func updateUserExercises() {
        exerciseViewModel.userExercises = chartManager.userExercises()
    }
    private func delete(at offsets: IndexSet) {
        let context = persistenceController.container.viewContext

        for index in offsets {
            context.delete(context.object(with: filteredExercises[index].objectID))
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
                        let exerciseButton = {
                            Button(role: .destructive) {
                                guard let index = filteredExercises.firstIndex(where: { $0.id == userExercise.id }) else { return }
                                delete(at: IndexSet(integer: index))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }()
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
                            .contextMenu {
                                exerciseButton
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                exerciseButton
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
