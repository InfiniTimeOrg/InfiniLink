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
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.alexemry.Infini-iOS")!.appendingPathComponent("InfiniLink.sqlite") // This is where we want to store the new database so widgets will be able to access it
        
        var defaultURL: URL?
        if let storeDescription = container.persistentStoreDescriptions.first, let url = storeDescription.url {
            defaultURL = FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        
        // If we haven't migrated yet, load the current stores
        if defaultURL == nil {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }
        container.loadPersistentStores { [self] storeDescription, error in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            if let url = defaultURL {
                let coordinator = container.persistentStoreCoordinator
                
                // Get the store object for the unmigrated database
                if let oldStore = coordinator.persistentStore(for: url) {
                    do {
                        let _ = try coordinator.migratePersistentStore(oldStore, to: storeURL, type: .sqlite)
                        
                        // Create a coordinator to delete the old store
                        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
                        fileCoordinator.coordinate(writingItemAt: url, options: .forDeleting, error: nil) { url in
                            do {
                                try FileManager.default.removeItem(at: url)
                            } catch {
                                log(error.localizedDescription, caller: "PersistenceController")
                            }
                        }
                    } catch {
                        log(error.localizedDescription, caller: "PersistenceController")
                    }
                }
            }
            
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
