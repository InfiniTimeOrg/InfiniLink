//
//  ExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData
import Charts

struct ExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.managedObjectContext) var viewContext
    
    @State private var showStartSheet = false
    
    private let fitnessCalculator = FitnessCalculator()
    private let recentCount = 3
    
    private var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? calendar.startOfDay(for: Date())
    }
    private var thisWeek: [UserExercise] {
        exerciseViewModel.userExercises.filter { ($0.startDate ?? .distantPast) >= startOfWeek }
    }
    private var recent: [UserExercise] {
        Array(exerciseViewModel.userExercises.sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }.prefix(recentCount))
    }
    
    private func duration(of exercise: UserExercise) -> TimeInterval {
        guard let start = exercise.startDate, let end = exercise.endDate else { return 0 }
        return max(0, end.timeIntervalSince(start))
    }
    
    private var dailyMinutes: [(day: Date, minutes: Double)] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else { return nil }
            let minutes = thisWeek.filter { calendar.isDate($0.startDate ?? .distantPast, inSameDayAs: day) }.reduce(0) { $0 + duration(of: $1) } / 60
            return (day, minutes)
        }
    }
    
    var body: some View {
        VStack {
            if exerciseViewModel.currentExercise != nil {
                ActiveExerciseView()
            } else {
                overview
            }
        }
        .onAppear {
            exerciseViewModel.userExercises = chartManager.userExercises()
        }
    }
    
    private var overview: some View {
        List {
            Section {
                let totalTime = thisWeek.reduce(0) { $0 + duration(of: $1) }
                let totalDistance = thisWeek.reduce(0) { $0 + $1.distance }
                let totalEnergy = thisWeek.reduce(0) { $0 + Double($1.caloriesBurned) }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    DetailHeaderSubItemView(title: "Workouts", value: "\(thisWeek.count)", icon: ("figure.run", .orange))
                    DetailHeaderSubItemView(title: "Time", value: Duration.seconds(totalTime).formatted(.units(allowed: [.hours, .minutes], width: .narrow)), icon: ("stopwatch", .green))
                    DetailHeaderSubItemView(title: "Distance", value: totalDistance > 0 ? fitnessCalculator.distanceString(meters: totalDistance) : "--", icon: ("map", .blue))
                    DetailHeaderSubItemView(title: fitnessCalculator.energyUnitLabel(short: true), value: totalEnergy > 0 ? "\(fitnessCalculator.energyValue(kcal: totalEnergy))" : "--", icon: ("flame.fill", .red))
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("This Week")
            }
            Section {
                Chart(dailyMinutes, id: \.day) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(.orange)
                    .accessibilityValue(Text(Duration.seconds(day.minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))))
                }
                .chartXAxis {
                    AxisMarks(values: dailyMinutes.map { $0.day }) {
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxisLabel("Minutes")
                .frame(height: 160)
                .padding(.vertical, 8)
            }
            Section {
                if recent.isEmpty {
                    Text("You haven't recorded any exercises yet. Tap \(Image(systemName: "plus")) to start one.")
                        .foregroundStyle(.gray)
                } else {
                    ForEach(recent) { userExercise in
                        NavigationLink {
                            ExerciseDetailView(userExercise: userExercise)
                        } label: {
                            ExerciseHistoryRowView(userExercise: userExercise, exercise: exerciseViewModel.exerciseOrPlaceholder(for: userExercise.exerciseId))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                exerciseViewModel.deleteUserExercise(userExercise)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                exerciseViewModel.deleteUserExercise(userExercise)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    if !exerciseViewModel.userExercises.isEmpty {
                        NavigationLink("View All") {
                            AllExercisesView()
                        }
                    }
                }
            } header: {
                Text("Recent")
            }
        }
        .navigationTitle("Exercise")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showStartSheet = true
                } label: {
                    Label("Start Exercise", systemImage: "plus")
                }
                NavigationLink {
                    ExerciseSettingsView()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showStartSheet) {
            StartExerciseView()
        }
    }
}

struct RecoverExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared

    @State private var showConfirmation = false

    let session: WorkoutSession

    private var exerciseName: String {
        return exerciseViewModel.exercise(for: session.exerciseId)?.name ?? "Workout"
    }

    var body: some View {
        NavigationView {
            ActionView(Action(title: "Exercise in progress", subtitle: "Started \(session.startDate.formatted(.relative(presentation: .named))). Resume where you left off, save it as-is, or discard it.", icon: exerciseViewModel.exercise(for: session.exerciseId)?.icon ?? "figure.run", accent: .blue, buttons: [
                ActionButton("Resume", action: {
                    exerciseViewModel.resumeRecoveredSession()
                }),
                ActionButton("Save & End", role: .cancel, action: {
                    exerciseViewModel.saveAndEndRecoveredSession()
                }),
                ActionButton("Discard", role: .destructive, action: {
                    showConfirmation = true
                })
            ]))
            .interactiveDismissDisabled()
            .toolbar {
                Button(role: .cancel) {
                    showConfirmation = true
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
        }
        .confirmationDialog("Active Exercise", isPresented: $showConfirmation) {
            Button(role: .destructive) {
                exerciseViewModel.discardRecoveredSession()
            } label: {
                Text("Discard")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to discard the active exercise?")
        }
    }
}

#Preview {
    NavigationView {
        RecoverExerciseView(session: WorkoutSession(exerciseId: "test"))
    }
}
