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
    
    @AppStorage("heartRateChartDataSelection") private var heartRateChartDataSelection = 0
    
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
            let oneHour: TimeInterval = 60 * 60
            let oneDay: TimeInterval = oneHour * 24
            let oneWeek: TimeInterval = oneDay * 7
            
            let timeInterval: TimeInterval = {
                switch heartRateChartDataSelection {
                case 1: return oneDay // Day
                case 2: return oneWeek // Week
                case 3:
                    let calendar = Calendar.current
                    let range = calendar.range(of: .weekOfMonth, in: .month, for: Date())
                    return oneWeek * TimeInterval(range?.count ?? 4) // Fallback to 4 weeks if range is nil
                default: return oneHour // Hour
                }
            }()
            
            return try viewContext.fetch(fetchRequest)
                .filter { record in
                    guard
                        let timestamp = record.timestamp?.timeIntervalSinceNow,
                        record.deviceId == bleManager.pairedDeviceID
                    else { return false }
                    
                    let secondsFromNow = abs(timestamp)
                    return secondsFromNow <= timeInterval
                }
        } catch {
            log("Error fetching heart points: \(error)", caller: "BLECharacteristicHandler")
            return []
        }
    }
    
    func stepPoints() -> [StepCounts] {
        let fetchRequest: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest).filter({ $0.deviceId == bleManager.pairedDeviceID })
        } catch {
            log("Error fetching step points: \(error)", caller: "BLECharacteristicHandler")
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
