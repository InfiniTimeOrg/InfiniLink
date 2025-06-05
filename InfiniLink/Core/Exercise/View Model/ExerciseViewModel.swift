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
    let persistenceController = PersistenceController.shared
    let userDefaults = UserDefaults(suiteName: "group.com.alexemry.Infini-iOS")
    
    @Published var exerciseTime: TimeInterval = 0
    @Published var stepsTaken: Int = 0
    @Published var currentExercise: Exercise?
    @Published var exercisePaused = false
    @Published var timer: Timer?
    @Published var userExercises = [UserExercise]()
    @Published var pinnedExercises = [String]()
    
    var appDidEnterBackgroundDate: Date?
    
    let exercises = [
        Exercise(id: "outdoor-run", name: "Outdoor Run", icon: "figure.run", components: [.heart, .steps], pace: .jog),
        Exercise(id: "outdoor-cycle", name: "Outdoor Cycle", icon: "figure.outdoor.cycle", components: [.heart]),
        Exercise(id: "indoor-run", name: "Indoor Run", icon: "figure.run.treadmill", components: [.heart, .steps], pace: .jog),
        Exercise(id: "indoor-cycle", name: "Indoor Cycle", icon: "figure.indoor.cycle", components: [.heart]),
        Exercise(id: "strength-training", name: "Strength Training", icon: "figure.strengthtraining.traditional", components: [.heart]),
        Exercise(id: "table-tennis", name: "Table Tennis", icon: "figure.table.tennis", components: [.heart]),
        Exercise(id: "tennis", name: "Tennis", icon: "figure.tennis", components: [.heart]),
        Exercise(id: "soccer", name: "Soccer", icon: "figure.indoor.soccer", components: [.heart, .steps], pace: .run),
        Exercise(id: "basketball", name: "Basketball", icon: "figure.basketball", components: [.heart, .steps], pace: .run),
        Exercise(id: "badminton", name: "Badminton", icon: "figure.badminton", components: [.heart, .steps], pace: .run),
        Exercise(id: "boxing", name: "Boxing", icon: "figure.boxing", components: [.heart]),
        Exercise(id: "skiing", name: "Skiing", icon: "figure.skiing.downhill", components: [.heart]),
        Exercise(id: "bowling", name: "Bowling", icon: "figure.bowling", components: [.heart, .steps]),
        Exercise(id: "figure.golf", name: "Golf", icon: "figure.golf", components: [.heart, .steps]),
        Exercise(id: "hockey", name: "Hockey", icon: "figure.hockey", components: [.heart, .steps], pace: .fastRun)
    ]
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        self.getPinnedExercises()
    }
    
    @objc func applicationDidEnterBackground(_ notification: NotificationCenter) {
        appDidEnterBackgroundDate = Date()
        
        if currentExercise != nil {
            stopTimer()
        }
    }
    
    @objc func applicationWillEnterForeground(_ notification: NotificationCenter) {
        guard let previousDate = appDidEnterBackgroundDate else { return }
        
        if currentExercise != nil && !exercisePaused {
            startTimer()
            
            let calendar = Calendar.current
            let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
            let seconds = difference.second!
            exerciseTime += Double(seconds)
        }
    }
    
    func getPinnedExercises() {
        let pinnedExercises = userDefaults?.array(forKey: "pinnedExercises") as? [String] ?? []
        self.pinnedExercises = pinnedExercises
    }
    
    func setPinnedExercises() {
        userDefaults?.set(self.pinnedExercises, forKey: "pinnedExercises")
    }
    
    func reset() {
        stepsTaken = 0
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
        startTimer()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func saveExercise(_ exercise: Exercise, startDate: Date, heartPoints: [HeartDataPoint]) {
        let context = persistenceController.container.viewContext
        let newExercise = UserExercise(context: context)
        
        newExercise.id = UUID()
        newExercise.startDate = startDate
        newExercise.endDate = Date()
        newExercise.exerciseId = exercise.id
        newExercise.heartPoints = NSSet(array: heartPoints)
        newExercise.steps = Int32(stepsTaken)
        newExercise.caloriesBurned = Int32(FitnessCalculator().calculateCaloriesBurned(steps: stepsTaken, pace: exercise.pace))
        newExercise.deviceId = BLEManager.shared.pairedDeviceID
        
        persistenceController.save()
        userExercises = ChartManager.shared.userExercises()
    }
    
    func isDateDuringExercise(_ date: Date) -> Bool {
        let exercises = ChartManager.shared.userExercises().filter { exercise in
            guard let endDate = exercise.endDate else { return true }
            
            // Use end date because it will be present in the day for the longest
            return Calendar.current.isDate(date, equalTo: endDate, toGranularity: .day)
        }
        
        return !exercises.isEmpty
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.exerciseTime += 1
        }
    }
}
