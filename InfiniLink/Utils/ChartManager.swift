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
    let viewContext = PersistenceController.shared.container.viewContext
    let bleManager = BLEManager.shared
    
    @AppStorage("heartRateChartDataSelection") var heartRateChartDataSelection = 0
    @AppStorage("stepChartDataSelection") var stepChartDataSelection = 0
    
    static let shared = ChartManager()
    
    func addStepDataPoint(steps: Int32, time: Date) {
        let heartRateDataPoint = StepCounts(context: viewContext)
        heartRateDataPoint.steps = steps
        heartRateDataPoint.timestamp = time
        heartRateDataPoint.deviceId = bleManager.pairedDeviceID
        
        do {
            try viewContext.save()
        } catch {
            log("Failed to save heart rate data point: \(error.localizedDescription)", caller: "ChartManager")
        }
    }
    
    func addHeartRateDataPoint(heartRate: Double, time: Date) {
        let heartRateDataPoint = HeartDataPoint(context: viewContext)
        heartRateDataPoint.value = heartRate
        heartRateDataPoint.timestamp = time
        heartRateDataPoint.deviceId = bleManager.pairedDeviceID
        
        do {
            try viewContext.save()
        } catch {
            log("Failed to save heart rate data point: \(error.localizedDescription)", caller: "ChartManager")
        }
    }
    
    func addBatteryDataPoint(batteryLevel: Double, time: Date) {
        let batteryDataPoint = BatteryDataPoint(context: viewContext)
        batteryDataPoint.value = batteryLevel
        batteryDataPoint.timestamp = time
        batteryDataPoint.deviceId = bleManager.pairedDeviceID
        
        do {
            try viewContext.save()
        } catch {
            log("Failed to save battery data point: \(error.localizedDescription)", caller: "ChartManager")
        }
    }
    
    func heartPoints() -> [HeartDataPoint] {
        let fetchRequest: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
                .filter { record in
                    return record.deviceId == bleManager.pairedDeviceID
                }
        } catch {
            log("Error fetching heart points: \(error)", caller: "BLECharacteristicHandler")
            return []
        }
    }
    
    func stepPoints() -> [StepCounts] {
        let fetchRequest: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
                .filter { record in
                    return record.deviceId == bleManager.pairedDeviceID
                }
        } catch {
            log("Error fetching step points: \(error)", caller: "StepChartView")
            return []
        }
    }
    
    func batteryPoints(for date: Date) -> [BatteryDataPoint] {
        let fetchRequest: NSFetchRequest<BatteryDataPoint> = BatteryDataPoint.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "time >= %@ AND time < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try viewContext.fetch(fetchRequest).filter({ $0.deviceId == bleManager.pairedDeviceID })
        } catch {
            log("Failed to fetch battery data points: \(error)", caller: "ChartManager")
            return []
        }
    }
}
