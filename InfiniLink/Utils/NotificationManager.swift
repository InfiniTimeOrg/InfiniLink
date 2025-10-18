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
    
    let bleWriteManager = BLEWriteManager()
    let bleManager = BLEManager.shared
    
    init() {
        if !PersonalizationController.shared.showSetupSheet {
            // Don't request permissions if the user hasn't had the chance to manually enable them
            requestNotificationAuthorization()
        }
    }
    
    @Published var canSendNotifications = false
    
    @AppStorage("watchNotifications") var watchNotifications = true
    @AppStorage("sendLowBatteryNotification") var sendBatteryNotifications = true
    @AppStorage("sendFullBatteryNotification") var sendFullBatteryNotification = true
    @AppStorage("sendLowBatteryNotificationToiPhone") var sendBatteryNotificationsToiPhone = true
    @AppStorage("sendLowBatteryNotificationToWatch") var sendBatteryNotificationsToWatch = true
    @AppStorage("lastBatteryLevelNotified") var lastBatteryLevelNotified: Double = -1
    
    @AppStorage("waterReminderAmount") var waterReminderAmount = 7
    @AppStorage("waterReminder") var waterReminder = true
    
    @AppStorage("minHeartRange") var minHeartRange = 40
    @AppStorage("maxHeartRange") var maxHeartRange = 150
    @AppStorage("heartRangeReminder") var heartRangeReminder = false
    @AppStorage("lastTimeMinHeartRangeNotified") var lastTimeMinHeartRangeNotified: Double = 0
    @AppStorage("lastTimeMaxHeartRangeNotified") var lastTimeMaxHeartRangeNotified: Double = 0
    
    private var nextReminderCheckDate: Date?
    private var waterReminderStartHour: Int = 8
    private var waterReminderEndHour: Int = 20
    private var waterReminderInterval: TimeInterval = 0
    private let tenMinutes = TimeInterval(60 * 10)
    
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
                log("Error sending notification: \(error.localizedDescription)", caller: "NotificationManager")
            }
        }
    }
}

// MARK: Battery
extension NotificationManager {
    func checkToSendLowBatteryNotification() {
        if watchNotifications && sendBatteryNotifications {
            let bat = bleManager.batteryLevel
            
            // Don't send a notification if we've already sent one with the same battery level
            guard lastBatteryLevelNotified == -1 || lastBatteryLevelNotified != bat else { return }
            
            if bat == 20 || bat == 10 || bat == 5 {
                self.sendLowBatteryNotification()
            } else if bat == 100 {
                self.sendFullyChargedBatteryNotification()
            }
            self.lastBatteryLevelNotified = bat
        }
    }
    
    private func sendLowBatteryNotification() {
        let bat = bleManager.batteryLevel
        let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: "\(String(format: "%.0f", bat))% " + NSLocalizedString("battery remaining", comment: ""))
        
        if sendBatteryNotificationsToiPhone ? (!bleManager.ancsAuthorized && sendBatteryNotificationsToWatch) : sendBatteryNotificationsToWatch { // Make sure we don't send any notifications to the watch where we're already sending a notif to the host when ANCS is enabled because the notification will ping twice
            self.bleWriteManager.sendNotification(notif)
        }
        if sendBatteryNotificationsToiPhone {
            self.sendNotificationToHost(notif)
        }
    }
    
    private func sendFullyChargedBatteryNotification() {
        let notif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: NSLocalizedString("\(DeviceManager.shared.name) is fully charged", comment: ""))
        self.sendNotificationToHost(notif)
    }
}

// MARK: Health
extension NotificationManager {
    func sendHeartRangeNotification(_ bpm: Int) {
        let currentTime = Date().timeIntervalSince1970
        
        // Don't localize these notifications because InfiniTime doesn't (most) characters from other languages
        if bpm < minHeartRange, (currentTime - lastTimeMinHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: "Heart Rate Low", subtitle: "Your heart rate fell below \(minHeartRange) BPM")
            )
            self.lastTimeMinHeartRangeNotified = currentTime
        }
        if bpm > maxHeartRange, (currentTime - lastTimeMaxHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: "Heart Rate High", subtitle: "Your heart rate rose above \(maxHeartRange)")
            )
            self.lastTimeMaxHeartRangeNotified = currentTime
        }
    }
    
    func setWaterRemindersPerDay() {
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
        
        if let nextReminderCheckDate, currentTime >= nextReminderCheckDate {
            if waterReminder {
                bleWriteManager.sendNotification(AppNotification(title: NSLocalizedString("Water Reminder", comment: ""), subtitle: NSLocalizedString("It's time to drink water", comment: "")))
            }
            
            // Don't include in conditional because we want to keep the reminders up-to-date in case the user reenables water reminders
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
        guard bleManager.ancsAuthorized else { return }
        
        let notif = AppNotification(title: NSLocalizedString("Reminders", comment: ""), subtitle: reminder.title + NSLocalizedString(" is due", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
    
    func sendEventDueNotification(_ event: EKEvent) {
        guard bleManager.ancsAuthorized else { return }
        
        let notif = AppNotification(title: NSLocalizedString("Calender", comment: ""), subtitle: event.title + NSLocalizedString(" is due", comment: ""))
        
        self.bleWriteManager.sendNotification(notif)
    }
}
