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
                if let error {
                    log(error.localizedDescription, caller: "HealthKitManager")
                    return
                }
                
                if success {
                    log("Steps successfully saved", type: .info, caller: "HealthKitManager")
                } else {
                    log("Unknown error while writing steps", caller: "HealthKitManager")
                }
            })
        }
    }
    
    func writeHeartRate(date: Date, dataToAdd: Double) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: dataToAdd), start: date, end: date)

        if healthStore?.authorizationStatus(for: heartRateType) == .sharingAuthorized && syncToAppleHealth {
            if let healthStore = healthStore {
                healthStore.save(heartRateSample, withCompletion: { success, error in
                    if let error = error {
                        log("Error saving heart rate: \(error.localizedDescription)", caller: "HealthKitManager")
                        return
                    }

                    if success {
                        log("Heart rate successfully saved", type: .info, caller: "HealthKitManager")
                    } else {
                        log("Unknown error while writing heart rate", caller: "HealthKitManager")
                    }
                })
            }
        }
    }
    
    func requestAuthorization() {
        let steps = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let heartRate = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        guard let healthStore = self.healthStore else { return }
        
        healthStore.requestAuthorization(toShare: [steps, heartRate], read: [steps]) { success, error in
            if let error = error {
                log(error.localizedDescription, caller: "HealthKitManager")
            }
        }
    }
}
