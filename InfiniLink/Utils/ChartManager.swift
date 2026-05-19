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
    @AppStorage("heartRateChartDataSelection") var heartRateChartDataSelection = 0
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    static let shared = ChartManager()
    
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
    var sevenDayPredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        return NSPredicate(format: predicateString, deviceId, start as NSDate)
    }
    var dayPredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        let startOfDay = calendar.startOfDay(for: Date())
        
        return NSPredicate(format: predicateString, deviceId, startOfDay as NSDate)
    }
    func monthPredicate(offset: Int = 0) -> NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        let calendar = Calendar.current
        let now = Date()
        
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let startOfOffsettedMonth = calendar.date(byAdding: .month, value: offset, to: startOfMonth),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfOffsettedMonth) else {
            return NSPredicate(value: false)
        }
        
        return NSPredicate(
            format: "deviceId == %@ AND timestamp >= %@ AND timestamp < %@",
            deviceId,
            startOfOffsettedMonth as NSDate,
            startOfNextMonth as NSDate
        )
    }
    var allTimePredicate: NSPredicate {
        let deviceId = bleManager.pairedDeviceID ?? ""
        return NSPredicate(format: "deviceId == %@", deviceId)
    }
    
    func addStepDataPoint(steps: Int32, time: Date) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let stepCount = StepCounts(context: context)
            stepCount.id = UUID()
            stepCount.steps = steps
            stepCount.timestamp = time
            stepCount.deviceId = self.bleManager.pairedDeviceID
            
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
    
    func heartPoints(predicate: NSPredicate? = nil) -> [HeartDataPoint] {
        let fetchRequest: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
        fetchRequest.predicate = predicate ?? dayPredicate
        
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
        } catch {
            log("Error fetching user exercises: \(error)", caller: "ChartManager")
            return []
        }
    }
    
    func disconnectMapPoint() -> DisconnectMapPoint? {
        guard let deviceId = bleManager.pairedDeviceID else { return nil }
        
        let context = persistenceController.container.viewContext
        
        let fetchRequest: NSFetchRequest<DisconnectMapPoint> = DisconnectMapPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "deviceId == %@", deviceId)
        fetchRequest.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(fetchRequest).first {
                return existing
            }
            
            let point = DisconnectMapPoint(context: context)
            point.deviceId = deviceId
            
            return point
        } catch {
            log("Error fetching disconnect point: \(error)", caller: "ChartManager")
            return nil
        }
    }
    
    func batteryPoints(predicate: NSPredicate? = nil) -> [BatteryDataPoint] {
        guard bleManager.pairedDeviceID != nil else { return [] }
        let fetchRequest: NSFetchRequest<BatteryDataPoint> = BatteryDataPoint.fetchRequest()
        fetchRequest.predicate = predicate ?? sevenDayPredicate
        
        do {
            return try persistenceController.container.viewContext.fetch(fetchRequest)
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
    
    func deleteAllDisconnectMapPoints(all: Bool = true) {
        let context = persistenceController.container.newBackgroundContext()
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DisconnectMapPoint.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetchRequest.fetchOffset = all ? 0 : 3
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
