//
//  InfiniLinkApp.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/2/24.
//

import SwiftUI
import CoreData
import BackgroundTasks

@main
struct InfiniLink: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        HealthKitManager.shared.requestAuthorization()
        
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { _ in
            RemindersManager.shared.fetchAllReminders()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
