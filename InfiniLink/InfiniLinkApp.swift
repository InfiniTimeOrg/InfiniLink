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
    let downloadManager = DownloadManager.shared
    let notificationManager = NotificationManager.shared
    let deviceManager = DeviceManager.shared
    
    @AppStorage("colorScheme") var colorScheme = "system"
    
    init() {
        HealthKitManager.shared.requestAuthorization()
        
        downloadManager.updateAvailable = downloadManager.checkForUpdates(currentVersion: deviceManager.firmware)
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(colorScheme == "light" ? .light : .dark)
            }
        }
    }
}
