//
//  ExerciseViewModel.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import SwiftUI
import CoreData

class ExerciseViewModel: ObservableObject {
    static let shared = ExerciseViewModel()
    
    let healthKitManager = HealthKitManager.shared
    
    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run", components: [.heart, .steps]),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle", components: [.heart]),
        Exercise(id: "indoor-run", name: "Indoor Run", icon: "figure.run.treadmill", components: [.heart, .steps]),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle", components: [.heart]),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis", components: [.heart]),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis", components: [.heart]),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer", components: [.heart, .steps]),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball", components: [.heart]),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton", components: [.heart]),
        Exercise(id: "strength-training", name: "Strength Training", icon: "figure.strengthtraining.traditional", components: [.heart])
    ]
    
    func timeString(from time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func saveExercise(_ exercise: String, startDate: Date, heartPoints: [HeartDataPoint], viewContext: NSManagedObjectContext) {
        let newExercise = UserExercise(context: viewContext)
        
        newExercise.id = UUID()
        newExercise.startDate = startDate
        newExercise.endDate = Date()
        newExercise.exerciseId = exercise
        
        for heartPoint in heartPoints {
            newExercise.addToHeartPoints(heartPoint)
        }
        
        saveContext(viewContext)
        healthKitManager.writeExerciseTime(startDate: startDate, endDate: Date()) { _, _ in }
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
