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
    
    @AppStorage("lastBatteryLevelNotified") var lastBatteryLevelNotified: Double = -1
    @AppStorage("lastHostBatteryLevelNotified") var lastHostBatteryLevelNotified: Double = -1
    
    @AppStorage("waterReminderAmount") var waterReminderAmount = 7
    @AppStorage("waterReminder") var waterReminder = true
    
    @AppStorage("minHeartRange") var minHeartRange = 40
    @AppStorage("maxHeartRange") var maxHeartRange = 150
    @AppStorage("heartRangeReminder") var heartRangeReminder = false
    @AppStorage("lastTimeMinHeartRangeNotified") var lastTimeMinHeartRangeNotified: Double = 0
    @AppStorage("lastTimeMaxHeartRangeNotified") var lastTimeMaxHeartRangeNotified: Double = 0
    
    @Published var canSendHostNotifs = false
    
    private let bleWriteManager = BLEWriteManager()
    private let bleManager = BLEManager.shared
    private let settings = NotificationSettingsManager.shared.settings
    private let batterySettings = NotificationSettingsManager.shared.settings.batterySettings
    
    private var nextReminderCheckDate: Date?
    private var waterReminderStartHour: Int = 8
    private var waterReminderEndHour: Int = 20
    private var waterReminderInterval: TimeInterval = 0
    
    private let thirtyMinutes = TimeInterval(60 * 30)
    
    init() {
        if !PersonalizationController.shared.showSetupSheet {
            // Don't request permissions if the user hasn't had the chance to manually enable them
            requestNotificationAuthorization()
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func requestNotificationAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.canSendHostNotifs = granted
            completion?(granted, error)
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
    func checkHostBatteryState() {
        let state = UIDevice.current.batteryState
        let level = UIDevice.current.batteryLevel * 100
        let currentTime = Date().timeIntervalSince1970
        
        let fullNotif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: NSLocalizedString("Your iPhone has reached \(String(format: "%.0f", level))%", comment: ""))
        let lowNotif = AppNotification(title: NSLocalizedString("Low Battery", comment: ""), subtitle: NSLocalizedString("Your iPhone has less than 20% battery remaining.", comment: ""))
        
        guard lastHostBatteryLevelNotified == -1 || (currentTime - lastTimeMinHeartRangeNotified) >= thirtyMinutes else { return } // Don't receive more than one notif in thirty minutes
        
        if state == .full {
            sendNotifications(fullNotif, batterySettings.fullBattery.iphone)
        } else if level == 20 && state != .charging {
            sendNotifications(lowNotif, batterySettings.lowBattery.iphone)
        }
        lastHostBatteryLevelNotified = currentTime
    }
    
    private func sendNotifications(_ notif: AppNotification, _ settings: NotifySettings) {
        if (!settings.sendToiPhone || !bleManager.ancsAuthorized) && settings.sendToWatch { // Don't send a notif to the watch while ancs is enabled and we're already sending to the host because ancs will already forward it (causing a duplicate)
            bleWriteManager.sendNotification(notif)
        }
        if settings.sendToiPhone {
            sendNotificationToHost(notif)
        }
    }
    
    func checkToSendBatteryNotifications() {
        let bat = bleManager.batteryLevel
        
        guard settings.watchNotificationsEnabled && (lastBatteryLevelNotified == -1 || lastBatteryLevelNotified != bat) else { return } // Don't send a notification if we've already sent one with the same battery levelelse { return }
        
        if batterySettings.customNotificationEnabled && bat == Double(batterySettings.customNotificationPercentage) {
            self.sendBatteryNotification(custom: true)
        } else if bat == 100 {
            self.sendFullyChargedBatteryNotification()
        } else if batterySettings.lowBattery.enabled && (bat == 20 || bat == 10 || bat == 5) {
            self.sendBatteryNotification(custom: false)
        }
        
        self.lastBatteryLevelNotified = bat
    }
    
    private func sendBatteryNotification(custom: Bool) {
        let bat = bleManager.batteryLevel
        let subtitle = "\(String(format: "%.0f", bat))% " + NSLocalizedString("battery remaining", comment: "")
        
        if custom {
            let notif = AppNotification(title: NSLocalizedString("Battery Alert", comment: ""), subtitle: subtitle)
            sendNotifications(notif, batterySettings.customNotificationSettings)
        } else {
            let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: subtitle)
            sendNotifications(notif, batterySettings.lowBattery.watch)
        }
    }
    
    private func sendFullyChargedBatteryNotification() {
        let notif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: NSLocalizedString("\(DeviceManager.shared.name) is fully charged", comment: ""))
        sendNotifications(notif, batterySettings.fullBattery.watch)
    }
}

// MARK: Health
extension NotificationManager {
    func sendHeartRangeNotification(_ bpm: Int) {
        guard heartRangeReminder else { return } // Disable this notification if the user has turned them off
        
        let currentTime = Date().timeIntervalSince1970
        let tenMinutes = TimeInterval(60 * 10)
        
        // Don't localize these notifications because InfiniTime doesn't (most) characters from other languages
        if bpm < minHeartRange, (currentTime - lastTimeMinHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate Low", comment: ""), subtitle: NSLocalizedString("Your heart rate fell below \(minHeartRange) BPM", comment: ""))
            )
            self.lastTimeMinHeartRangeNotified = currentTime
        }
        if bpm > maxHeartRange, (currentTime - lastTimeMaxHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate High", comment: ""), subtitle: NSLocalizedString("Your heart rate rose above \(maxHeartRange) BPM", comment: ""))
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
        var endComponents = DateComponents()
        startComponents.hour = waterReminderStartHour
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
        self.sendNotificationToHost(notif)
    }
}
