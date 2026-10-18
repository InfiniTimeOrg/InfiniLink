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
    
    @AppStorage("lastTimeMinHeartRangeNotified") var lastTimeMinHeartRangeNotified: Double = 0
    @AppStorage("lastTimeMaxHeartRangeNotified") var lastTimeMaxHeartRangeNotified: Double = 0

    @Published var canSendHostNotifs = false

    private let bleWriteManager = BLEWriteManager()
    private let bleManager = BLEManager.shared

    // Read live so a settings change mid session updates
    private var settings: NotificationSettings { NotificationSettingsManager.shared.settings }
    private var batterySettings: BatterySettings { settings.batterySettings }
    
    private var hostFullNotified = false
    private var hostLowNotified = false
    
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
        
        setWaterRemindersPerDay()
        
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func requestNotificationAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.canSendHostNotifs = granted
                completion?(granted, error)
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
    func checkHostBatteryState() {
        let state = UIDevice.current.batteryState
        let level = UIDevice.current.batteryLevel * 100
        let currentTime = Date().timeIntervalSince1970
        
        // Re-arm each alert once the battery leaves the state it fired for
        if state != .full {
            hostFullNotified = false
        }
        if level > 20 || state != .unplugged {
            hostLowNotified = false
        }
        
        // At most one iPhone battery notification every thirty minutes
        guard level >= 0, lastHostBatteryLevelNotified == -1 || (currentTime - lastHostBatteryLevelNotified) >= thirtyMinutes else { return }
        
        if state == .full && !hostFullNotified {
            let notif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: NSLocalizedString("Your iPhone has reached \(String(format: "%.0f", level))%", comment: ""))
            sendNotifications(notif, batterySettings.fullBattery.iphone)
            
            hostFullNotified = true
            lastHostBatteryLevelNotified = currentTime
        } else if level <= 20 && state == .unplugged && !hostLowNotified {
            let notif = AppNotification(title: NSLocalizedString("Low Battery", comment: ""), subtitle: String(localized: "Your iPhone has less than \(0.2, format: .percent) battery remaining."))
            sendNotifications(notif, batterySettings.lowBattery.iphone)
            
            hostLowNotified = true
            lastHostBatteryLevelNotified = currentTime
        }
    }
    
    private func sendNotifications(_ notif: AppNotification, _ settings: NotifySettings) {
        // Skip the direct-to-watch send when ANCS is already mirroring the iPhone notification to the watch
        let ancsWillMirrorToWatch = settings.sendToiPhone && bleManager.ancsAuthorized
        if settings.sendToWatch && !ancsWillMirrorToWatch {
            bleWriteManager.sendNotification(notif)
        }
        if settings.sendToiPhone {
            sendNotificationToHost(notif)
        }
    }
    
    func checkToSendBatteryNotifications() {
        let bat = bleManager.batteryLevel
        let previous = lastBatteryLevelNotified
        lastBatteryLevelNotified = bat
        
        // Skip if watch notifications are off, this is the first reading, or the level hasn't changed
        guard settings.watchNotificationsEnabled, previous >= 0, bat != previous else { return }
        
        // Compare against the previous reading so a level that skips past a threshold still notifies
        let crossedBelow = { (threshold: Double) in previous > threshold && bat <= threshold }
        
        if batterySettings.customNotificationEnabled && crossedBelow(batterySettings.customNotificationPercentage) {
            sendBatteryNotification(custom: true)
        } else if bat == 100 {
            sendFullyChargedBatteryNotification()
        } else if batterySettings.lowBattery.enabled && [20, 10, 5].contains(where: crossedBelow) {
            sendBatteryNotification(custom: false)
        }
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
        let heartSettings = settings.heartSettings
        guard settings.watchNotificationsEnabled, heartSettings.rangeReminderEnabled else { return }

        let currentTime = Date().timeIntervalSince1970
        let tenMinutes = TimeInterval(60 * 10)

        // Don't localize these notifications because InfiniTime doesn't (most) characters from other languages
        if bpm < heartSettings.minRange, (currentTime - lastTimeMinHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate Low", comment: ""), subtitle: NSLocalizedString("Your heart rate fell below \(heartSettings.minRange) BPM", comment: ""))
            )
            self.lastTimeMinHeartRangeNotified = currentTime
        }
        if bpm > heartSettings.maxRange, (currentTime - lastTimeMaxHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate High", comment: ""), subtitle: NSLocalizedString("Your heart rate rose above \(heartSettings.maxRange) BPM", comment: ""))
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
        waterReminderInterval = totalTimeInterval / Double(settings.waterReminderAmount + 1)
    }
    
    func checkAndNotifyForWaterReminders() {
        let currentTime = Date()
        
        if let nextReminderCheckDate, currentTime >= nextReminderCheckDate {
            if settings.waterReminderEnabled {
                bleWriteManager.sendNotification(AppNotification(title: NSLocalizedString("Water Reminder", comment: ""), subtitle: NSLocalizedString("It's time to drink water", comment: "")))
            }
            
            // Don't include in conditional because we want to keep the reminders up-to-date in case the user reenables water reminders
            self.nextReminderCheckDate = getNextReminderDate()
        }
    }
    
    private func getNextReminderDate() -> Date {
        let calendar = Calendar.current
        let next = Date().addingTimeInterval(waterReminderInterval)
        let hour = calendar.component(.hour, from: next)
        
        guard hour < waterReminderStartHour || hour >= waterReminderEndHour else { return next }
        
        // Outside the reminder window, so wait until it next opens
        guard let windowStart = calendar.date(bySettingHour: waterReminderStartHour, minute: 0, second: 0, of: next) else { return next }
        
        return hour < waterReminderStartHour ? windowStart : calendar.date(byAdding: .day, value: 1, to: windowStart) ?? next
    }
}

// MARK: Goals
extension NotificationManager {
    func sendStepGoalReachedNotification() {
        let notif = AppNotification(title: NSLocalizedString("Goal Reached", comment: ""), subtitle: NSLocalizedString("You've reached your step goal", comment: ""))
        
        if !bleManager.ancsAuthorized {
            self.bleWriteManager.sendNotification(notif)
        }
        self.sendNotificationToHost(notif)
    }
}
