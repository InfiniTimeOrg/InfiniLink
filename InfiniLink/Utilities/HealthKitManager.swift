//
//  HealthKitManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/22/23.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var heartRate: Int = 0
    var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func writeSteps(date: Date, stepsToAdd: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let stepsSample = HKQuantitySample(type: stepType, quantity: HKQuantity.init(unit: HKUnit.count(), doubleValue: stepsToAdd), start: date, end: date)
        
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
    
    func writeHeartRate(date: Date, dataToAdd: Double) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        let heartRateSample = HKQuantitySample(type: heartRateType, quantity: HKQuantity.init(unit: HKUnit.count(), doubleValue: dataToAdd), start: date, end: date)
        
        if let healthStore = healthStore {
            healthStore.save(heartRateSample, withCompletion: { success, error in
                
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
    
    func fetchStepCount() {
        let healthStore = HKHealthStore()
        let stepType = HKSampleType.quantityType(forIdentifier: .stepCount)!
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictEndDate)
        
        var stepCount: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            defer {
                semaphore.signal()
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            stepCount = Int(sum.doubleValue(for: .count()))
        }
        
        healthStore.execute(query)
        
        semaphore.wait()
        
        self.stepCount = stepCount
    }
    
    func fetchHeartRate() {
        let healthStore = HKHealthStore()
        let heartRateType = HKSampleType.quantityType(forIdentifier: .heartRate)!
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictEndDate)
        
        var heartRate: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
            defer {
                semaphore.signal()
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let heartRateQuantity = sample.quantity
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRateBPM = Int(heartRateQuantity.doubleValue(for: heartRateUnit))
                
                heartRate = heartRateBPM
            }
        }
        
        healthStore.execute(query)
        semaphore.wait()
        
        self.heartRate = heartRate
    }
}

