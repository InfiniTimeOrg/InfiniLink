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
	
	static let shared = ChartManager()
    
    func addHeartRateDataPoint(heartRate: Double, time: Date) {
        let heartRateDataPoint = HeartDataPoint(context: viewContext)
        heartRateDataPoint.value = heartRate
        heartRateDataPoint.timestamp = time
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save heart rate data point: \(error)")
        }
    }
    
    func addBatteryDataPoint(batteryLevel: Double, time: Date) {
        let batteryDataPoint = BatteryDataPoint(context: viewContext)
        batteryDataPoint.value = batteryLevel
        batteryDataPoint.timestamp = time
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save battery data point: \(error)")
        }
    }
    
    func fetchHeartRateDataPoints(for date: Date) -> [HeartDataPoint] {
        let fetchRequest: NSFetchRequest<HeartDataPoint> = HeartDataPoint.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "time >= %@ AND time < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch heart rate data points: \(error)")
        }
    }
    
    func fetchBatteryDataPoints(for date: Date) -> [BatteryDataPoint] {
        let fetchRequest: NSFetchRequest<BatteryDataPoint> = BatteryDataPoint.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "time >= %@ AND time < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            fatalError("Failed to fetch battery data points: \(error)")
        }
    }
}

extension Date {
    func posHour() -> Date {
        return Date(timeIntervalSinceReferenceDate:
                        (timeIntervalSinceReferenceDate / (3600.0)).rounded(.down) * (3600.0) + ((timeIntervalSinceReferenceDate / (3600.0)).rounded(.down) * (3600.0) - (timeIntervalSinceReferenceDate / (3600.0 * 3.0)).rounded(.down) * (3600.0 * 3.0)))
    }
}
