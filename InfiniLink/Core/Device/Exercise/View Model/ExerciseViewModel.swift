//
//  ExerciseViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation

class ExerciseViewModel: ObservableObject {
    static let shared = ExerciseViewModel()
    
    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run"),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle"),
        Exercise(id: "indoor-run", name: "Outdoor Run", icon: "figure.run.treadmill"),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle"),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis"),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis"),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer"),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball"),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton")
    ]
}
