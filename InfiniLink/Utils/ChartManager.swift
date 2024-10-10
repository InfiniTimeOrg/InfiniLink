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
    
    @AppStorage("heartRateChartDataSelection") private var dataSelection = 0
    
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
    
    func convertHeartPointsToChartPoints(points: FetchedResults<HeartDataPoint>) -> [LineChartDataPoint] {
        var dataPoints: [LineChartDataPoint] = []
        let dateFormat = DateFormatter()
        
        dateFormat.dateFormat = "MMM d\nH:mm:ss"
        
        let timeInterval: TimeInterval = {
            switch dataSelection {
            case 1:  // Day (24 hours)
                return 86400
            case 2:  // Week
                return 86400 * 7
            case 3:  // Month
                return 2628003
            case 4:  // 6 mo
                return 157680117
            case 5:  // Year
                return 31536000
            default:  // Hour
                return 3600
            }
        }()
        
        for dataPoint in points {
            guard let timestamp = dataPoint.timestamp else { continue }
            
            let timeSinceNow = abs(timestamp.timeIntervalSinceNow)
            
            if timeSinceNow <= timeInterval {
                let formattedDate = dateFormat.string(from: timestamp)
                dataPoints.append(LineChartDataPoint(
                    value: dataPoint.value,
                    xAxisLabel: "Time",
                    description: formattedDate,
                    date: timestamp
                ))
            }
        }
        
        if let first = dataPoints.first, dataPoints.count == 1 {
            let point = LineChartDataPoint(value: first.value, xAxisLabel: "Time", description: dateFormat.string(from: first.date!), date: first.date!)
            return [point, point]
        } else if dataPoints.count < 1 {
            return [LineChartDataPoint(value: 0), LineChartDataPoint(value: 0)]
        }
        
        return dataPoints
    }
}
