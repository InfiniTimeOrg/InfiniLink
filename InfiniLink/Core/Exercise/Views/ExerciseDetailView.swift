//
//  ExerciseDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI
import Charts
import CoreData
import CoreLocation

struct ExerciseDetailView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartDataPoints: FetchedResults<HeartDataPoint>

    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared

    private let fitnessCalculator = FitnessCalculator()

    let userExercise: UserExercise

    var heartPoints: [HeartDataPoint] {
        return heartDataPoints.filter({
            guard let timestamp = $0.timestamp else { return false }
            guard let startDate = userExercise.startDate else { return false }
            guard let endDate = userExercise.endDate else { return false }

            return startDate <= timestamp && timestamp <= endDate
        })
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        guard let json = userExercise.routeJSON, let data = json.data(using: .utf8) else { return [] }
        guard let points = try? JSONDecoder().decode([RoutePoint].self, from: data) else { return [] }

        return points.map { $0.coordinate }
    }
    
    func exercise() -> Exercise {
        return exerciseViewModel.exercises.first(where: { $0.id == userExercise.exerciseId ?? "" })!
    }
    
    func timeDifferenceFormatted(startDate: Date, endDate: Date) -> String {
        let difference = endDate.timeIntervalSince(startDate)
        let totalSeconds = Int(difference)
        
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") and \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") and \(seconds) second\(seconds == 1 ? "" : "s")"
        } else {
            return "\(seconds) second\(seconds == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    VStack(spacing: 7) {
                        Image(systemName: exercise().icon)
                            .font(.system(size: 50).weight(.medium))
                        VStack(spacing: 4) {
                            Text(exercise().name)
                                .font(.largeTitle.weight(.bold))
                            Text(userExercise.startDate!.formatted())
                               .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                if routeCoordinates.count > 1 {
                    Section("Route") {
                        RouteMapView(coordinates: routeCoordinates)
                            .frame(height: 220)
                            .listRowInsets(EdgeInsets())
                    }
                }
                Section("Time") {
                    let startDate = userExercise.startDate!

                    Text("Starting on \(startDate.formatted(.dateTime.day().month())) at \(startDate.formatted(.dateTime.hour().minute())), the exercise lasted \(timeDifferenceFormatted(startDate: startDate, endDate: userExercise.endDate!)).")
                }
                if userExercise.distance > 0 {
                    Section("Distance") {
                        Text("You covered \(fitnessCalculator.distanceString(meters: userExercise.distance)).")
                    }
                }
                Section("Heart Rate") {
                    let heartValues = heartPoints.compactMap({ $0.value })
                    let min = Int(heartValues.min() ?? 0)
                    let max = Int(heartValues.max() ?? 0)

                    if heartPoints.count > 1 {
                        Chart {
                            ForEach(heartPoints, id: \.objectID) { point in
                                LineMark(
                                    x: .value("Time", point.timestamp ?? Date()),
                                    y: .value("BPM", point.value)
                                )
                                .foregroundStyle(.red)
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYScale(domain: Swift.max(0, min - 10)...(max + 10))
                        .frame(height: 180)
                        Text("Averaging at \(Double(heartValues.reduce(0, +)) / Double(heartValues.count), format: .number.precision(.fractionLength(0))) BPM, your heart rate ranged from \(min) to \(max) BPM.")
                    } else {
                        Text("There wasn't any heart rate data recorded for this exercise.")
                    }
                }
                if exercise().components.contains(.steps) {
                    Section("Steps") {
                        Text("You took \(userExercise.steps) step\(userExercise.steps == 1 ? "" : "s") and burned \(userExercise.caloriesBurned > 1 ? fitnessCalculator.energyString(kcal: Double(userExercise.caloriesBurned)) : "less than one calorie").")
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseDetailView(userExercise: {
        let exercise = UserExercise()
        
        exercise.endDate = Date()
        exercise.startDate = Date.distantPast
        exercise.exerciseId = "outdoor-run"
        exercise.heartPoints = []
        
        return exercise
    }())
}
