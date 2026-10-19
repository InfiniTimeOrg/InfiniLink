//
//  PersistenceController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "InfiniLink")
        
        guard let description = container.persistentStoreDescriptions.first else {
            log("No persistent store descriptions")
            return
        }
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

extension PersistenceController {
    func save() {
        guard container.viewContext.hasChanges else { return }
        
        container.viewContext.perform {
            do {
                try self.container.viewContext.save()
            } catch {
                log("Failed to save view context: \(error.localizedDescription)", caller: "PersistenceController")
            }
        }
    }
}
