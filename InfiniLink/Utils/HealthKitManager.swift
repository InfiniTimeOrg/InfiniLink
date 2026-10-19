//
//  HealthKitManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/22/23.
//

import SwiftUI
import HealthKit
import CoreData

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @AppStorage("syncToAppleHealth") var syncToAppleHealth = true
    @AppStorage("syncStepsToAppleHealth") var syncSteps = true
    @AppStorage("syncHeartRateToAppleHealth") var syncHeartRate = true
    @AppStorage("syncCaloriesToAppleHealth") var syncCalories = true
    @AppStorage("syncExerciseToAppleHealth") var syncExercise = true
    @AppStorage("syncSleepToAppleHealth") var syncSleep = true
    @AppStorage("fillStepsFromAppleHealth") var fillStepsFromAppleHealth = true

    @Published var healthStore: HKHealthStore?
    
    private var pendingHeartRateSamples = [HKQuantitySample]()
    private var lastStepFillDate: Date?
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(flushHeartRateSamples), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(flushHeartRateSamples), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func writeSteps(_ stepsToAdd: Int, for date: Date = Date()) {
        guard stepsToAdd > 0 else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!

        let stepsSample = HKQuantitySample(type: stepType, quantity: HKQuantity.init(unit: HKUnit.count(), doubleValue: Double(stepsToAdd)), start: date, end: date)
        
        if let healthStore, healthStore.authorizationStatus(for: stepType) == .sharingAuthorized && syncToAppleHealth && syncSteps {
            healthStore.save(stepsSample, withCompletion: { success, error in
                if success {
                    log("Steps successfully saved", type: .info, caller: "HealthKitManager")
                } else if let error {
                    log("Error saving steps: \(error.localizedDescription)", caller: "HealthKitManager")
                }
            })
        }
    }
    
    func writeHeartRate(date: Date, dataToAdd: Double) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return }

        let sample = HKQuantitySample(type: heartRateType, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: dataToAdd), start: date, end: date)

        if let healthStore, healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized && syncToAppleHealth && syncHeartRate {
            pendingHeartRateSamples.append(sample)
            
            // Save in batches instead of one write per reading
            if let first = pendingHeartRateSamples.first, pendingHeartRateSamples.count >= 10 || date.timeIntervalSince(first.startDate) >= 60 {
                flushHeartRateSamples()
            }
        }
    }
    
    @objc func flushHeartRateSamples() {
        guard let healthStore, !pendingHeartRateSamples.isEmpty else { return }
        
        let samples = pendingHeartRateSamples
        pendingHeartRateSamples = []
        
        healthStore.save(samples) { success, error in
            if success {
                log("Saved \(samples.count) heart rate samples", type: .info, caller: "HealthKitManager")
            } else if let error {
                log("Error saving heart rate: \(error.localizedDescription)", caller: "HealthKitManager")
            }
        }
    }
    
    func saveWorkout(_ workout: HKWorkout, activeEnergyKcal: Double = 0, from start: Date? = nil, to end: Date? = nil) {
        let workoutType = HKObjectType.workoutType()
        guard let healthStore, healthStore.authorizationStatus(for: workoutType) == .sharingAuthorized && syncToAppleHealth && syncExercise else { return }

        healthStore.save(workout) { success, error in
            guard success else {
                if let error {
                    log("Error saving exercise: \(error.localizedDescription)", caller: "HealthKitManager")
                }
                return
            }
            log("Exercise successfully saved", type: .info, caller: "HealthKitManager")

            // Add the workout's energy as a real sample so it counts toward the daily active energy total (not just the workout card)
            guard activeEnergyKcal > 0, let start, let end, self.syncCalories,
                  let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
                  healthStore.authorizationStatus(for: energyType) == .sharingAuthorized else { return }

            let energySample = HKQuantitySample(type: energyType, quantity: HKQuantity(unit: .kilocalorie(), doubleValue: activeEnergyKcal), start: start, end: end)
            healthStore.add([energySample], to: workout) { _, addError in
                if let addError {
                    log("Error attaching workout energy: \(addError.localizedDescription)", caller: "HealthKitManager")
                }
            }
        }
    }
    
    func saveCalories(kcal: Double, date: Date = Date()) {
        guard kcal > 0 else { return }
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kcal)
        let sample = HKQuantitySample(type: caloriesType, quantity: caloriesQuantity, start: date, end: date)

        if let healthStore, healthStore.authorizationStatus(for: caloriesType) == .sharingAuthorized && syncToAppleHealth && syncCalories {
            healthStore.save(sample) { success, error in
                if success {
                    log("Calories successfully saved", type: .info, caller: "HealthKitManager")
                } else if let error {
                    log("Error saving calories: \(error.localizedDescription)", type: .info, caller: "HealthKitManager")
                }
            }
        }
    }
    
    func writeSleep(start: Date, minutes: [SleepState], completion: @escaping (Bool) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let healthStore, healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized && syncToAppleHealth && syncSleep, !minutes.isEmpty else {
            completion(false)
            return
        }
        
        var samples = [HKCategorySample]()
        var runStart = 0
        for index in 1...minutes.count where index == minutes.count || minutes[index] != minutes[runStart] {
            let state = minutes[runStart]
            if state != .noData {
                let value = state == .asleep ? HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue : HKCategoryValueSleepAnalysis.awake.rawValue
                let sampleStart = start.addingTimeInterval(Double(runStart) * 60)
                let sampleEnd = start.addingTimeInterval(Double(index) * 60)
                samples.append(HKCategorySample(type: sleepType, value: value, start: sampleStart, end: sampleEnd))
            }
            runStart = index
        }
        
        guard !samples.isEmpty else {
            completion(false)
            return
        }
        
        healthStore.save(samples) { success, error in
            if success {
                log("Sleep successfully saved", type: .info, caller: "HealthKitManager")
            } else if let error {
                log("Error saving sleep: \(error.localizedDescription)", caller: "HealthKitManager")
            }
            completion(success)
        }
    }
    
    // Fill days the watch wasn't connected with steps from other sources in Apple Health
    func fillMissingStepDays(deviceId: String, maxDays: Int = 30) {
        guard fillStepsFromAppleHealth, let healthStore, let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        // Don't run twice at once or a day could get added twice
        guard Date().timeIntervalSince(lastStepFillDate ?? .distantPast) > 3600 else { return }
        lastStepFillDate = Date()

        let calendar = Calendar.current
        let context = PersistenceController.shared.container.newBackgroundContext()
        context.perform {
            let request: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
            request.predicate = NSPredicate(format: "deviceId == %@", deviceId)
            let records = (try? context.fetch(request)) ?? []

            let recordedDays = Set(records.compactMap { $0.timestamp.map { calendar.startOfDay(for: $0) } })
            let today = calendar.startOfDay(for: Date())
            guard let firstDay = recordedDays.min(),
                  let earliest = calendar.date(byAdding: .day, value: -maxDays, to: today) else { return }

            var day = max(firstDay, earliest)
            var missingDays = [Date]()
            while day < today {
                if !recordedDays.contains(day) {
                    missingDays.append(day)
                }
                day = calendar.date(byAdding: .day, value: 1, to: day) ?? today
            }

            let notFromApp = NSCompoundPredicate(notPredicateWithSubpredicate: HKQuery.predicateForObjects(from: HKSource.default()))
            for missingDay in missingDays {
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: missingDay) else { continue }

                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [HKQuery.predicateForSamples(withStart: missingDay, end: nextDay), notFromApp])
                let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    guard let steps = statistics?.sumQuantity()?.doubleValue(for: .count()), steps > 0 else { return }

                    context.perform {
                        let record = StepCounts(context: context)
                        record.id = UUID()
                        record.deviceId = deviceId
                        record.steps = Int32(steps)
                        record.timestamp = nextDay.addingTimeInterval(-60)

                        do {
                            try context.save()
                        } catch {
                            log("Error saving filled step day: \(error.localizedDescription)", caller: "HealthKitManager")
                        }
                    }
                }
                healthStore.execute(query)
            }
        }
    }

    func requestAuthorization() {
        let workoutType = HKObjectType.workoutType()
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else { return }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return }
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        guard let healthStore = self.healthStore else { return }
        
        healthStore.requestAuthorization(toShare: [stepsType, heartRateType, caloriesType, workoutType, sleepType], read: [stepsType, heartRateType]) { success, error in
            if let error = error {
                log(error.localizedDescription, caller: "HealthKitManager")
            }
        }
    }
}
