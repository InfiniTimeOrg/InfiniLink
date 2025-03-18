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
        
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { _ in
            RemindersManager.shared.fetchAllItems()
        }
        
        downloadManager.updateAvailable = downloadManager.checkForUpdates(currentVersion: deviceManager.firmware)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme({
                    switch colorScheme {
                    case "light":
                        return .light
                    case "dark":
                        return .dark
                    default:
                        return .none
                    }
                }())
        }
    }
}
