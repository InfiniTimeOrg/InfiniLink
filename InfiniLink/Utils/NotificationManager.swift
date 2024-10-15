//
//  NotificationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI
import UserNotifications
import EventKit

struct AppNotification {
    let title: String
    let subtitle: String
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private var batteryIsUnderTwenty: Bool = false
    private var batteryIsUnderTen: Bool = false
    
    let bleWriteManager = BLEWriteManager()
    let bleManager = BLEManager.shared
    
    init() {
        if !PersonalizationController.shared.showSetupSheet {
            requestNotificationAuthorization()
        }
    }
    
    @Published var canSendNotifications = false
    
    @AppStorage("watchNotifications") var watchNotifications = true
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.canSendNotifications = true
            } else if error != nil {
                self.canSendNotifications = false
            }
        }
    }
    
    func sendNotificationToHost(_ notif: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = notif.title
        content.body = notif.subtitle
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Battery
extension NotificationManager {
    func checkToSendLowBatteryNotification() {
        let bat = bleManager.batteryLevel
        let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: "\(String(format: "%.0f", bat))% " + NSLocalizedString("battery remaining", comment: ""))
        
        if watchNotifications && !bleManager.firstConnect {
            if bat > 20 {
                batteryIsUnderTwenty = false
                batteryIsUnderTen = false
            } else if (bat <= 20 && bat > 10) && !batteryIsUnderTwenty {
                self.bleWriteManager.sendNotification(notif)
                self.sendNotificationToHost(notif)
                
                self.batteryIsUnderTwenty = true
            } else if (bat <= 10 && bat > 5) && !batteryIsUnderTen {
                self.bleWriteManager.sendNotification(notif)
                self.sendNotificationToHost(notif)
                
                self.batteryIsUnderTen = true
            }
        }
    }
}

// MARK: Goals
extension NotificationManager {
    func sendExerciseTimeGoalReachedNotification() {
        let notif = AppNotification(title: NSLocalizedString("Goal Reached", comment: ""), subtitle: NSLocalizedString("You've reached your exercise time goal!", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
    
    func sendCaloriesGoalReachedNotification() {
        let notif = AppNotification(title: NSLocalizedString("Goal Reached", comment: ""), subtitle: NSLocalizedString("You've reached your calorie goal!", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
}

// MARK: Reminders
extension NotificationManager {
    func sendReminderDueNotification(_ reminder: EKReminder) {
        let notif = AppNotification(title: NSLocalizedString("Reminder Due", comment: ""), subtitle: reminder.title + NSLocalizedString(" is due.", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
}
