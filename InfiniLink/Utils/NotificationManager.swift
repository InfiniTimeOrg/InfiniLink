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
    @AppStorage("sendLowBatteryNotificationToiPhone") var sendLowBatteryNotificationToiPhone = true
    @AppStorage("sendLowBatteryNotificationToWatch") var sendLowBatteryNotificationToWatch = true
    
    @AppStorage("waterReminderAmount") var waterReminderAmount = 7
    
    private var nextReminderCheckDate: Date?
    private var waterReminderStartHour: Int = 8
    private var waterReminderEndHour: Int = 20
    private var waterReminderInterval: TimeInterval = 0
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.canSendNotifications = true
                } else if error != nil {
                    self.canSendNotifications = false
                }
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
        if watchNotifications {
            let bat = bleManager.batteryLevel
            
            if bat > 20 {
                batteryIsUnderTwenty = false
                batteryIsUnderTen = false
            } else if (bat <= 20 && bat > 10) && !batteryIsUnderTwenty {
                self.sendLowBatteryNotification()
                self.batteryIsUnderTwenty = true
            } else if (bat <= 10 && bat > 5) && !batteryIsUnderTen {
                self.sendLowBatteryNotification()
                self.batteryIsUnderTen = true
            }
        }
    }
    
    private func sendLowBatteryNotification() {
        let bat = bleManager.batteryLevel
        let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: "\(String(format: "%.0f", bat))% " + NSLocalizedString("battery remaining", comment: ""))
        
        if sendLowBatteryNotificationToWatch {
            self.bleWriteManager.sendNotification(notif)
        }
        if sendLowBatteryNotificationToiPhone {
            self.sendNotificationToHost(notif)
        }
    }
}

extension NotificationManager {
    func setWaterRemindersPerDay() {
        waterReminderAmount = waterReminderAmount
        
        calculateReminderInterval()
        
        nextReminderCheckDate = getNextReminderDate()
    }
    
    private func calculateReminderInterval() {
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = waterReminderStartHour
        var endComponents = DateComponents()
        endComponents.hour = waterReminderEndHour
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return
        }
        
        let totalTimeInterval = endDate.timeIntervalSince(startDate)
        
        waterReminderInterval = totalTimeInterval / Double(waterReminderAmount)
    }
    
    func checkAndNotifyForWaterReminders() {
        let currentTime = Date()
        
        if let nextReminderCheckDate = nextReminderCheckDate, currentTime >= nextReminderCheckDate {
            bleWriteManager.sendNotification(AppNotification(title: NSLocalizedString("Water Reminder", comment: ""), subtitle: NSLocalizedString("It's time to drink water", comment: "")))
            
            self.nextReminderCheckDate = getNextReminderDate()
        }
    }
    
    private func getNextReminderDate() -> Date {
        let currentDate = Date()
        
        return currentDate.addingTimeInterval(waterReminderInterval)
    }
}

// MARK: Goals
extension NotificationManager {
    func sendStepGoalReachedNotification() {
        let notif = AppNotification(title: NSLocalizedString("Goal Reached", comment: ""), subtitle: NSLocalizedString("You've reached your steps goal", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
}

// MARK: Reminders
extension NotificationManager {
    func sendReminderDueNotification(_ reminder: EKReminder) {
        let notif = AppNotification(title: NSLocalizedString("Reminders", comment: ""), subtitle: reminder.title + NSLocalizedString(" is due", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
    
    func sendEventDueNotification(_ event: EKEvent) {
        let notif = AppNotification(title: NSLocalizedString("Calender", comment: ""), subtitle: event.title + NSLocalizedString(" is due", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
}
