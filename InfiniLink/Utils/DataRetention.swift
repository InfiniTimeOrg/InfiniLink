//
//  DataRetention.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreData
import SwiftUI

struct DataRetention {
    static let shared = DataRetention()
    
    let persistenceController = PersistenceController.shared
    
    static let monthOptions = [0, 6, 12, 24]
    
    // Exercises (and their heart points) are never cleared by age
    private let agedEntities = [
        ("BatteryDataPoint", "timestamp < %@"),
        ("DisconnectMapPoint", "timestamp < %@"),
        ("HeartDataPoint", "timestamp < %@ AND exercise == nil"),
        ("MotionActivityPoint", "timestamp < %@"),
        ("SleepSession", "end < %@"),
        ("StepCounts", "timestamp < %@")
    ]
    private let deviceEntities = ["BatteryDataPoint", "DisconnectMapPoint", "HeartDataPoint", "MotionActivityPoint", "SleepSession", "StepCounts", "UserExercise"]
    
    // 0 is forever
    var months: Int {
        UserDefaults.standard.integer(forKey: "dataRetentionMonths")
    }
    
    private func delete(_ requests: [NSFetchRequest<NSFetchRequestResult>], completion: (() -> Void)? = nil) {
        let context = persistenceController.container.newBackgroundContext()
        
        context.perform {
            var deleted = [NSManagedObjectID]()
            for request in requests {
                let delete = NSBatchDeleteRequest(fetchRequest: request)
                delete.resultType = .resultTypeObjectIDs
                do {
                    let result = try context.execute(delete) as? NSBatchDeleteResult
                    deleted += result?.result as? [NSManagedObjectID] ?? []
                } catch {
                    log("Error deleting stored data: \(error.localizedDescription)", caller: "DataRetention")
                }
            }
            
            // Batch deletes skip the view context so we have to merge them in
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deleted], into: [persistenceController.container.viewContext])
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func deleteOldData(completion: (() -> Void)? = nil) {
        guard months > 0, let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
            completion?()
            return
        }
        
        delete(agedEntities.map { entity, format in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            request.predicate = NSPredicate(format: format, cutoff as NSDate)
            return request
        }, completion: completion)
    }
    
    // Don't use DeviceManager.watches, it loads async and could still be empty
    private func unpairedPredicate() -> NSPredicate {
        let paired = ((try? persistenceController.container.viewContext.fetch(Device.fetchRequest())) ?? []).compactMap { $0.uuid }
        return NSPredicate(format: "deviceId != nil AND NOT (deviceId IN %@)", paired)
    }
    
    func unpairedRecordCount() -> Int {
        let context = persistenceController.container.viewContext
        
        return deviceEntities.reduce(0) { total, entity in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            request.predicate = unpairedPredicate()
            return total + ((try? context.count(for: request)) ?? 0)
        }
    }
    
    func deleteUnpairedData(completion: (() -> Void)? = nil) {
        delete(deviceEntities.map { entity in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            request.predicate = unpairedPredicate()
            return request
        }, completion: completion)
    }
}
