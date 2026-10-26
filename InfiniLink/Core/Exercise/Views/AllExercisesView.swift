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
    
    private var filteredExercises: [UserExercise] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = exerciseViewModel.userExercises.sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) }
        if query.isEmpty {
            return sorted
        }
        return sorted.filter { userExercise in
            guard let startDate = userExercise.startDate else { return false }
            let exercise = exerciseViewModel.exerciseOrPlaceholder(for: userExercise.exerciseId)
            
            return exercise.name.lowercased().contains(query) || startDate.formatted().lowercased().contains(query)
        }
    }
    
    private func updateUserExercises() {
        exerciseViewModel.userExercises = chartManager.userExercises()
    }
    private func delete(at offsets: IndexSet) {
        let exercises = filteredExercises
        for index in offsets {
            exerciseViewModel.deleteUserExercise(exercises[index])
        }
        
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
                    ForEach(filteredExercises) { userExercise in
                        let exerciseButton = {
                            Button(role: .destructive) {
                                guard let index = filteredExercises.firstIndex(where: { $0.id == userExercise.id }) else { return }
                                delete(at: IndexSet(integer: index))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }()
                        let exercise = exerciseViewModel.exerciseOrPlaceholder(for: userExercise.exerciseId)
                        Group {
                            NavigationLink {
                                ExerciseDetailView(userExercise: userExercise)
                            } label: {
                                ExerciseHistoryRowView(userExercise: userExercise, exercise: exercise)
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

struct ExerciseHistoryRowView: View {
    let userExercise: UserExercise
    let exercise: Exercise
    
    private var duration: String? {
        guard let start = userExercise.startDate, let end = userExercise.endDate else { return nil }
        return Duration.seconds(end.timeIntervalSince(start)).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
    
    var body: some View {
        HStack {
            Image(systemName: exercise.icon)
                .font(.system(size: 24).weight(.medium))
                .foregroundStyle(.orange)
                .frame(minWidth: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body.weight(.medium))
                Text(userExercise.startDate?.formatted(.dateTime.month(.abbreviated).day().year().hour(.localized).minute()) ?? NSLocalizedString("Unknown date", comment: ""))
                    .foregroundStyle(Color.gray)
            }
            Spacer()
            if let duration {
                Text(duration)
                    .foregroundStyle(.gray)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
