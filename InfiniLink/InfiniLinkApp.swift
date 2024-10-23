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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

class AppDelegate: NSObject, UIApplicationDelegate {
    let remindersManager = RemindersManager.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.alexemry.Infini-iOS.remindercheck", using: nil) { task in
            print("Setting up background task")
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        scheduleAppRefresh()
        
        return true
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.alexemry.Infini-iOS.remindercheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        DispatchQueue.main.async {
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule app refresh: \(error.localizedDescription)")
            }
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        let expirationHandler = {
            task.setTaskCompleted(success: false)
            print("Task could not be completed")
            self.scheduleAppRefresh()
        }
        
        task.expirationHandler = expirationHandler
        remindersManager.checkForDueReminders(date: Date())
        
        print("Task completed")
        task.setTaskCompleted(success: true)
        self.scheduleAppRefresh()
    }
}
