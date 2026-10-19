//
//  CustomExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI
import HealthKit

struct CustomExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var icon = "figure.mixed.cardio"
    @State private var tracksSteps = true
    @State private var tracksRoute = false
    @State private var activityType = HKWorkoutActivityType.other

    private let icons = [
        "figure.mixed.cardio", "figure.walk", "figure.hiking", "figure.run", "figure.outdoor.cycle", "figure.pool.swim",
        "figure.rower", "figure.elliptical", "figure.stair.stepper", "figure.yoga", "figure.pilates", "figure.dance",
        "figure.climbing", "figure.cross.training", "figure.core.training", "figure.flexibility", "figure.skating", "figure.volleyball"
    ]
    private let activityTypes: [(String, HKWorkoutActivityType)] = [
        ("Other", .other),
        ("Walking", .walking),
        ("Hiking", .hiking),
        ("Running", .running),
        ("Cycling", .cycling),
        ("Swimming", .swimming),
        ("Rowing", .rowing),
        ("Elliptical", .elliptical),
        ("Stair Climbing", .stairClimbing),
        ("Yoga", .yoga),
        ("Pilates", .pilates),
        ("Dance", .socialDance),
        ("Climbing", .climbing),
        ("Cross Training", .crossTraining),
        ("Core Training", .coreTraining),
        ("Flexibility", .flexibility),
        ("Skating", .skatingSports),
        ("Volleyball", .volleyball)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { symbol in
                            Button {
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(icon == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(symbol))
                            .accessibilityAddTraits(icon == symbol ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section {
                    Picker("Workout Type", selection: $activityType) {
                        ForEach(activityTypes, id: \.1) { type in
                            Text(LocalizedStringKey(type.0)).tag(type.1)
                        }
                    }
                    Toggle("Count Steps", isOn: $tracksSteps)
                    Toggle("Record Route", isOn: $tracksRoute)
                } footer: {
                    Text("The workout type is used when saving to Apple Health. Heart rate is always recorded.")
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        exerciseViewModel.addCustomExercise(CustomExerciseDefinition(name: name.trimmingCharacters(in: .whitespaces), icon: icon, tracksSteps: tracksSteps, tracksRoute: tracksRoute, activityType: activityType))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CustomExerciseView()
}
