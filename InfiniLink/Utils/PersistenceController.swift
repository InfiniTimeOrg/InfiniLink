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
        container.loadPersistentStores { storeDescription, error in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    func save() {
        guard container.viewContext.hasChanges else { return }
        
        container.viewContext.perform {
            do {
                try self.container.viewContext.save()
            } catch {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                log("Failed to save view context: \(error.localizedDescription)", caller: "PersistenceController")
            }
        }
    }
}
