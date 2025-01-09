//
//  ChartManager.swift
//  ChartManager
//
//  Created by Alex Emry on 9/19/21.
//

import Foundation
import SwiftUI
import CoreData
import SwiftUICharts

class ChartManager: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext
    
    @AppStorage("heartRateChartDataSelection") private var heartRateChartDataSelection = 0
    
    static let shared = ChartManager()
    
    func addHeartRateDataPoint(heartRate: Double, time: Date) {
        let heartRateDataPoint = HeartDataPoint(context: viewContext)
        heartRateDataPoint.value = heartRate
        heartRateDataPoint.timestamp = time
        
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
        
        do {
            try viewContext.save()
        } catch {
            log("Failed to save battery data point: \(error.localizedDescription)", caller: "ChartManager")
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
    
    func convert(_ points: [HeartDataPoint]) -> [LineChartDataPoint] {
        var dataPoints: [LineChartDataPoint] = []
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "MMM d\nH:mm:ss"
        
        for point in points {
            dataPoints.append(LineChartDataPoint(value: point.value, xAxisLabel: NSLocalizedString("Date", comment: ""), description: dateFormat.string(from: point.timestamp!), date: point.timestamp!))
        }
        
        return dataPoints
    }
}
