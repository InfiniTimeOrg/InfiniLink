//
//  InfiniLinkApp.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/2/24.
//

import SwiftUI
import CoreData

@main
struct InfiniLink: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        HealthKitManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
