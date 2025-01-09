//
//  ExerciseDetailView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ExerciseDetailView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartDataPoints: FetchedResults<HeartDataPoint>
    
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    
    let userExercise: UserExercise
    
    var heartPoints: [HeartDataPoint] {
        return heartDataPoints.filter({
            guard let timestamp = $0.timestamp else { return false }
            guard let startDate = userExercise.startDate else { return false }
            guard let endDate = userExercise.endDate else { return false }
            
            return startDate <= timestamp && timestamp <= endDate
        })
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
        
        print(difference)
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else if minutes > 0 {
            return "\(minutes) min \(seconds) sec"
        } else {
            return "\(seconds) sec"
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
                Section {
                    HStack {
                        Text("Elapsed Time")
                        Spacer()
                        Text(timeDifferenceFormatted(startDate: userExercise.startDate!, endDate: userExercise.endDate!))
                            .foregroundStyle(.gray)
                    }
                    if heartPoints.count > 1 {
                        HStack {
                            Text("Heart Rate")
                            Spacer()
                            Text("\(Int(heartPoints.compactMap({ $0.value }).min() ?? 0)) - \(Int(heartPoints.compactMap({ $0.value }).max() ?? 0))")
                                .foregroundStyle(.gray)
                        }
                    }
                    if exercise().components.contains(.steps) {
                        HStack {
                            Text("Total Steps")
                            Spacer()
                            Text("800")
                                .foregroundStyle(.gray)
                        }
                    }
                    HStack {
                        Text("Total Tracks Played")
                        Spacer()
                        Text("\(userExercise.playedTracks?.count ?? 0)")
                            .foregroundStyle(.gray)
                    }
                }
                Section("Heart Rate") {
                    HeartChartView(heartPoints: heartPoints)
                        .frame(height: geo.size.width / 1.6)
                }
                .listRowBackground(Color.clear)
                if let tracksSet = userExercise.playedTracks as? Set<PlayedTrack>, !tracksSet.isEmpty {
                    let tracks = Array(tracksSet).sorted(by: { $0.timestamp ?? Date() < $1.timestamp ?? Date() })
                    
                    Section("Played Tracks") {
                        ForEach(tracks) { track in
                            if let title = track.title, let artist = track.artist {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(title)
                                        .fontWeight(.bold)
                                    Text(artist)
                                }
                            }
                        }
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
