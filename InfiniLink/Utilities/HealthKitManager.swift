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
    
    func readCurrentSteps(completion: @escaping (Double?, Error?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity()?.doubleValue(for: HKUnit.count()) else {
                    completion(nil, error)
                    return
                }
                completion(sum, nil)
            }
        }

        healthStore?.execute(query)
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
