//
//  ChartManager.swift
//  ChartManager
//
//  Created by Alex Emry on 9/19/21.
//

import Foundation
import SwiftUI
import CoreData

class ChartManager: ObservableObject {
    let persistenceController = PersistenceController.shared
    let bleManager = BLEManager.shared
    
    private let predicateString = "deviceId == %@ AND timestamp >= %@"
    private let calendar = Calendar.current
    
    var weekPredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        // Get the days of the current week, not just -7 days from now
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        return NSPredicate(format: predicateString, deviceId, startOfWeek as NSDate)
    }
    var dayPredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        let startOfDay = calendar.startOfDay(for: Date())
        
        return NSPredicate(format: predicateString, deviceId, startOfDay as NSDate)
    }
    var allTimePredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        return NSPredicate(format: "deviceId == %@", deviceId)
    }
    
    @AppStorage("heartRateChartDataSelection") var heartRateChartDataSelection = 0
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    static let shared = ChartManager()
    
    func addStepDataPoint(steps: Int32, time: Date) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let heartRateDataPoint = StepCounts(context: context)
            heartRateDataPoint.steps = steps
            heartRateDataPoint.timestamp = time
            heartRateDataPoint.deviceId = self.bleManager.pairedDeviceID
            
            do {
                try context.save()
            } catch {
                log("Error saving step point: \(error.localizedDescription)")
            }
        }
    }
    
    func addHeartRateDataPoint(heartRate: Double, time: Date) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let heartRateDataPoint = HeartDataPoint(context: context)
            heartRateDataPoint.value = heartRate
            heartRateDataPoint.timestamp = time
            heartRateDataPoint.deviceId = self.bleManager.pairedDeviceID
            
            do {
                try context.save()
            } catch {
                log("Error saving heart point: \(error.localizedDescription)")
            }
        }
    }
    
    func addBatteryDataPoint(batteryLevel: Double, time: Date) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let batteryDataPoint = BatteryDataPoint(context: context)
            batteryDataPoint.value = batteryLevel
            batteryDataPoint.timestamp = time
            batteryDataPoint.deviceId = self.bleManager.pairedDeviceID
            
            do {
                try context.save()
            } catch {
                log("Error saving battery point: \(error.localizedDescription)")
            }
        }
    }
    
    func heartPoints() -> [HeartDataPoint] {
        guard let deviceId = bleManager.pairedDeviceID else { return [] }
        
        let fetchRequest: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deviceId == %@", deviceId)
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest)
        } catch {
            log("Error fetching heart points: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func stepsToday() -> StepCounts? {
        return stepPoints().first
    }
    
    func stepPoints(predicate: NSPredicate? = nil) -> [StepCounts] {
        let fetchRequest: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
        fetchRequest.predicate = predicate ?? dayPredicate
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest)
        } catch {
            log("Error fetching step points: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func userExercises() -> [UserExercise] {
        guard let deviceId = bleManager.pairedDeviceID else { return [] }
                
        let fetchRequest: NSFetchRequest<UserExercise> = UserExercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deviceId == %@", deviceId)
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest)
                .filter { record in
                    return record.deviceId == bleManager.pairedDeviceID
                }
        } catch {
            log("Error fetching user exercises: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func disconnectMapPoints() -> [DisconnectMapPoint] {
        guard let deviceId = bleManager.pairedDeviceID else { return [] }
                
        let fetchRequest: NSFetchRequest<DisconnectMapPoint> = DisconnectMapPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deviceId == %@", deviceId)
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest)
                .filter { record in
                    return record.deviceId == bleManager.pairedDeviceID
                }
        } catch {
            log("Error fetching disconnect points: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func batteryPoints(for date: Date) -> [BatteryDataPoint] {
        guard let deviceId = bleManager.pairedDeviceID else { return [] }
        let fetchRequest: NSFetchRequest<BatteryDataPoint> = BatteryDataPoint.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "deviceId == %@ AND time >= %@ AND time < %@", deviceId, startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest).filter({ $0.deviceId == bleManager.pairedDeviceID })
        } catch {
            log("Failed to fetch battery data points: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func deleteAllUserExercises() {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserExercise.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(batchDeleteRequest)
                try context.save()
            } catch {
                log("Failed to delete user exercises: \(error)", caller: "ChartManager")
            }
        }
    }
    
    func deleteAllDisconnectMapPoints() {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DisconnectMapPoint.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(batchDeleteRequest)
                try context.save()
            } catch {
                log("Failed to delete disconnect pins: \(error)", caller: "ChartManager")
            }
        }
    }
}
