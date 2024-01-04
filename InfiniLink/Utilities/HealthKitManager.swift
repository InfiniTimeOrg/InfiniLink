//
//  HealthKitManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/22/23.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func writeSteps(date: Date, stepsToAdd: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let stepsSample = HKQuantitySample(type: stepType, quantity: HKQuantity.init(unit: HKUnit.count(), doubleValue: stepsToAdd), start: date, end: date)
        
        if healthStore?.authorizationStatus(for: stepType) == .sharingAuthorized {
            if let healthStore = healthStore {
                healthStore.save(stepsSample, withCompletion: { success, error in
                    
                    if error != nil {
                        print(error?.localizedDescription as Any)
                        return
                    }
                    
                    if success {
                        print("Steps successfully saved in HealthKit")
                        return
                    } else {
                        print("Unhandled case!")
                    }
                    
                })
            }
        }
    }
    
    func writeHeartRate(date: Date, dataToAdd: Double) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: dataToAdd), start: date, end: date)

        if healthStore?.authorizationStatus(for: heartRateType) == .sharingAuthorized {
            if let healthStore = healthStore {
                healthStore.save(heartRateSample, withCompletion: { success, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }

                    if success {
                        print("Heart rate successfully saved in HealthKit")
                    } else {
                        print("Unhandled case!")
                    }
                })
            }
        }
    }
    
    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let heartRate = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        guard let healthStore = self.healthStore else { return }
        
        healthStore.requestAuthorization(toShare: [stepType, heartRate], read: [stepType, heartRate]) { success, error in
            if let error = error {
                print(error)
            }
        }
    }
}

