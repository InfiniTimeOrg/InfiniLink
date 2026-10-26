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

    @State private var gpxURL: URL?
    @State private var showDeleteConfirmation = false
    @State private var deleteOnDisappear = false
    
    @Environment(\.dismiss) var dismiss

    var heartPoints: [HeartDataPoint] {
        return heartDataPoints.filter({
            guard let timestamp = $0.timestamp else { return false }
            guard let startDate = userExercise.startDate else { return false }
            guard let endDate = userExercise.endDate else { return false }

            return startDate <= timestamp && timestamp <= endDate
        })
    }

    var routePoints: [RoutePoint] {
        guard let json = userExercise.routeJSON, let data = json.data(using: .utf8) else { return [] }

        return (try? JSONDecoder().decode([RoutePoint].self, from: data)) ?? []
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        return routePoints.map { $0.coordinate }
    }

    private var isImperial: Bool {
        return PersonalizationController.shared.units == .imperial
    }

    private func paceString(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60) + (isImperial ? " /mi" : " /km")
    }

    private func gpxFile() -> URL? {
        let name = "\(exercise().name) \(userExercise.startDate?.formatted(date: .numeric, time: .omitted) ?? "")".replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).gpx")
        do {
            try WorkoutAnalysis.gpx(for: routePoints, name: exercise().name).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            log("Failed to write GPX: \(error.localizedDescription)", caller: "ExerciseDetailView")
            return nil
        }
    }
    
    func exercise() -> Exercise {
        return exerciseViewModel.exerciseOrPlaceholder(for: userExercise.exerciseId)
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

                    Text("Starting on \(startDate.formatted(.dateTime.day().month())) at \(startDate.formatted(.dateTime.hour(.localized).minute())), the exercise lasted \(timeDifferenceFormatted(startDate: startDate, endDate: userExercise.endDate!)).")
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
                if heartPoints.count > 1 {
                    let maxHeartRate = WorkoutAnalysis.maxHeartRate(age: PersonalizationController.shared.calculatedAge)
                    let zones = WorkoutAnalysis.zones(for: heartPoints.compactMap { point in
                        point.timestamp.map { ($0, point.value) }
                    }, maxHeartRate: maxHeartRate)
                    let total = max(zones.reduce(0) { $0 + $1.duration }, 1)
                    
                    Section {
                        ForEach(zones) { zone in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(zone.name)
                                        .fontWeight(.medium)
                                    Text("\(Int(zone.range.lowerBound * maxHeartRate))–\(Int(zone.range.upperBound * maxHeartRate)) BPM")
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Text(Duration.seconds(zone.duration).formatted(.time(pattern: .minuteSecond)))
                                        .monospacedDigit()
                                }
                                GeometryReader { bar in
                                    Capsule()
                                        .fill(Color.red.opacity(0.25 + 0.15 * Double(zone.id)))
                                        .frame(width: max(4, bar.size.width * zone.duration / total))
                                }
                                .frame(height: 6)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    } header: {
                        Text("Heart Rate Zones")
                    } footer: {
                        Text("Zones are based on an estimated maximum heart rate of \(Int(maxHeartRate)) BPM from the age in your health details.")
                    }
                }
                let splits = WorkoutAnalysis.splits(for: routePoints, unitMeters: isImperial ? 1609.344 : 1000)
                if !splits.isEmpty {
                    Section(isImperial ? "Splits (mi)" : "Splits (km)") {
                        Chart(splits) { split in
                            BarMark(
                                x: .value("Split", "\(split.id)"),
                                y: .value("Pace", split.duration / 60)
                            )
                            .foregroundStyle(split.isPartial ? Color.blue.opacity(0.5) : Color.blue)
                            .accessibilityValue(Text(paceString(split.duration)))
                        }
                        .chartYAxisLabel("Minutes")
                        .frame(height: 160)
                        .padding(.vertical, 6)
                        ForEach(splits) { split in
                            HStack {
                                Text(split.isPartial ? "\(split.id)*" : "\(split.id)")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(paceString(split.duration))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                if exercise().components.contains(.steps) {
                    Section("Steps") {
                        Text("You took \(userExercise.steps) step\(userExercise.steps == 1 ? "" : "s") and burned \(userExercise.caloriesBurned > 1 ? fitnessCalculator.energyString(kcal: Double(userExercise.caloriesBurned)) : "less than one calorie").")
                    }
                }
            }
        }
        .toolbar {
            if let gpxURL {
                ShareLink(item: gpxURL) {
                    Label("Export Route", systemImage: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Exercise", isPresented: $showDeleteConfirmation) {
            Button("Delete Exercise", role: .destructive) {
                deleteOnDisappear = true
                dismiss()
            }
        } message: {
            Text("This exercise will be deleted from InfiniLink.")
        }
        .onAppear {
            if gpxURL == nil && routePoints.count > 1 {
                gpxURL = gpxFile()
            }
        }
        // Wait until the view is gone so it doesn't read the deleted object
        .onDisappear {
            if deleteOnDisappear {
                exerciseViewModel.deleteUserExercise(userExercise)
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
