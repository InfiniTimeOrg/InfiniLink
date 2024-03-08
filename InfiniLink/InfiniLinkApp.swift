//
//  InfiniLinkApp.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

@main
struct InfiniLink: App {
    let persistenceController = PersistenceController.shared
    
    @ObservedObject var healthKitManager = HealthKitManager()
    
    init() {
        healthKitManager.requestAuthorization()
        requestNotificationAuthorization()
    }
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                NotificationManager.shared.canSendNotifications = true
            } else if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
