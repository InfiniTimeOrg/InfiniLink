//
//  HealthKitManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/22/23.
//

import SwiftUI
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @AppStorage("syncToAppleHealth") var syncToAppleHealth = true
    
    var healthStore: HKHealthStore?
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func writeSteps(_ stepsToAdd: Int, for date: Date = Date()) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let stepsSample = HKQuantitySample(type: stepType, quantity: HKQuantity.init(unit: HKUnit.count(), doubleValue: Double(stepsToAdd)), start: date, end: date)
        
        if let healthStore, healthStore.authorizationStatus(for: stepType) == .sharingAuthorized && syncToAppleHealth {
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

        if let healthStore, healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized && syncToAppleHealth {
            healthStore.save(sample, withCompletion: { success, error in
                if success {
                    log("Heart rate successfully saved", type: .info, caller: "HealthKitManager")
                } else if let error {
                    log("Error saving heart rate: \(error.localizedDescription)", caller: "HealthKitManager")
                }
            })
        }
    }
    
    func saveExercise(minutes: Double, date: Date = Date()) {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }

        let exerciseQuantity = HKQuantity(unit: HKUnit.minute(), doubleValue: minutes)
        let sample = HKQuantitySample(type: exerciseType, quantity: exerciseQuantity, start: date, end: date)

        if let healthStore, healthStore.authorizationStatus(for: exerciseType) == .sharingAuthorized && syncToAppleHealth {
            healthStore.save(sample) { success, error in
                if success {
                    log("Exercise successfully saved", type: .info, caller: "HealthKitManager")
                } else if let error {
                    log("Error saving exercise: \(error.localizedDescription)", caller: "HealthKitManager")
                }
            }
        }
    }
    
    func saveCalories(kcal: Double, date: Date = Date()) {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: kcal)
        let sample = HKQuantitySample(type: caloriesType, quantity: caloriesQuantity, start: date, end: date)

        if let healthStore, healthStore.authorizationStatus(for: caloriesType) == .sharingAuthorized && syncToAppleHealth {
            healthStore.save(sample) { success, error in
                if success {
                    log("Calories successfully saved", type: .info, caller: "HealthKitManager")
                } else if let error {
                    log("Error saving calories: \(error.localizedDescription)", type: .info, caller: "HealthKitManager")
                }
            }
        }
    }
    
    func requestAuthorization() {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else { return }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return }
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        
        guard let healthStore = self.healthStore else { return }
        
        healthStore.requestAuthorization(toShare: [stepsType, heartRateType, caloriesType, exerciseType], read: [stepsType, heartRateType]) { success, error in
            if let error = error {
                log(error.localizedDescription, caller: "HealthKitManager")
            }
        }
    }
}
