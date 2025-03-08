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
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "InfiniLink")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() async {
        do {
            try await container.viewContext.perform {
                try container.viewContext.save()
            }
        } catch {
            log("Unresolved error saving context: \(error.localizedDescription)", caller: "PersistenceController")
        }
    }
}
