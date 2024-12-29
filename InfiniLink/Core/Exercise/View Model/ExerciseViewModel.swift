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
    
    @Published var exerciseTime: TimeInterval = 0
    @Published var currentExercise: Exercise?
    @Published var exercisePaused = false
    
    var appDidEnterBackgroundDate: Date?
    
    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run", components: [.heart, .steps]),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle", components: [.heart]),
        Exercise(id: "indoor-run", name: "Indoor Run", icon: "figure.run.treadmill", components: [.heart, .steps]),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle", components: [.heart]),
        Exercise(id: "strength-training", name: "Strength Training", icon: "figure.strengthtraining.traditional", components: [.heart]),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis", components: [.heart]),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis", components: [.heart]),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer", components: [.heart, .steps]),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball", components: [.heart, .steps]),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton", components: [.heart, .steps]),
        Exercise(id: "boxing", name: "Boxing", icon: "figure.boxing", components: [.heart]),
        Exercise(id: "skiing", name: "Skiing", icon: "figure.skiing.downhill", components: [.heart]),
        Exercise(id: "bowling", name: "Bowling", icon: "figure.bowling", components: [.heart, .steps]),
        Exercise(id: "figure.golf", name: "Golf", icon: "figure.golf", components: [.heart, .steps]),
        Exercise(id: "hockey", name: "Hockey", icon: "figure.hockey", components: [.heart, .steps])
    ]
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        appDidEnterBackgroundDate = Date()
    }
    
    @objc func applicationWillEnterForeground(_ notification: NotificationCenter) {
        guard let previousDate = appDidEnterBackgroundDate else { return }
        
        if currentExercise != nil && !exercisePaused {
            let calendar = Calendar.current
            let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
            let seconds = difference.second!
            exerciseTime += Double(seconds)
        }
    }
    
    func reset() {
        exerciseTime = 0
        exercisePaused = false
    }
    
    func timeString() -> String {
        let hours = Int(exerciseTime) / 3600
        let minutes = (Int(exerciseTime) % 3600) / 60
        let seconds = Int(exerciseTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func startExercise(_ exercise: Exercise) {
        reset()
        currentExercise = exercise
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
        // TODO: add step values
        
        saveContext(viewContext)
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            log("Error saving context: \(error.localizedDescription)", caller: "ExerciseViewModel")
        }
    }
}
