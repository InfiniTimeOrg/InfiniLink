//
//  NotificationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI
import UserNotifications

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
    
    private var lastActiveDate = Date()
    private var inactivityBaselineSteps: Int?
    private var hasStepsSinceConnect = false
    
    private var previousStepsCache: (key: String, steps: [Date: Int])?
    
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
        } else {
            refreshAuthorizationStatus()
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
    
    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.canSendHostNotifs = settings.authorizationStatus == .authorized
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
            let notif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: String(localized: "Your iPhone has reached \(level / 100, format: .percent.precision(.fractionLength(0)))"))
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
        let subtitle = String(localized: "\(bat / 100, format: .percent.precision(.fractionLength(0))) battery remaining")
        
        if custom {
            let notif = AppNotification(title: NSLocalizedString("Battery Alert", comment: ""), subtitle: subtitle)
            sendNotifications(notif, batterySettings.customNotificationSettings)
        } else {
            let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: subtitle)
            sendNotifications(notif, batterySettings.lowBattery.watch)
        }
    }
    
    private func sendFullyChargedBatteryNotification() {
        let notif = AppNotification(title: NSLocalizedString("Fully Charged", comment: ""), subtitle: String(localized: "\(DeviceManager.shared.name) is fully charged"))
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

        if bpm < heartSettings.minRange, (currentTime - lastTimeMinHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate Low", comment: ""), subtitle: String(localized: "Your heart rate fell below \(heartSettings.minRange) BPM"))
            )
            self.lastTimeMinHeartRangeNotified = currentTime
            recordHeartRangeNotification(low: true)
        }
        if bpm > heartSettings.maxRange, (currentTime - lastTimeMaxHeartRangeNotified) >= tenMinutes {
            self.bleWriteManager.sendNotification(
                AppNotification(title: NSLocalizedString("Heart Rate High", comment: ""), subtitle: String(localized: "Your heart rate rose above \(heartSettings.maxRange) BPM"))
            )
            self.lastTimeMaxHeartRangeNotified = currentTime
            recordHeartRangeNotification(low: false)
        }
    }
    
    private func heartRangeKey(low: Bool) -> String {
        low ? "lowHeartRangeNotificationDates" : "highHeartRangeNotificationDates"
    }
    
    private func recordHeartRangeNotification(low: Bool) {
        let dates = heartRangeNotificationsToday(low: low) + [Date()]
        UserDefaults.standard.set(dates.map { $0.timeIntervalSince1970 }, forKey: heartRangeKey(low: low))
    }
    
    func heartRangeNotificationsToday(low: Bool) -> [Date] {
        let timestamps = UserDefaults.standard.array(forKey: heartRangeKey(low: low)) as? [Double] ?? []
        return timestamps.map { Date(timeIntervalSince1970: $0) }.filter { Calendar.current.isDateInToday($0) }
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

// MARK: Inactivity
extension NotificationManager {
    private var activeStepThreshold: Int { 50 }
    
    func updateActivity(steps: Int) {
        hasStepsSinceConnect = true
        
        // Steps reset at midnight, so reset the baseline
        guard let baseline = inactivityBaselineSteps, steps >= baseline else {
            inactivityBaselineSteps = steps
            return
        }
        
        if steps - baseline >= activeStepThreshold {
            inactivityBaselineSteps = steps
            lastActiveDate = Date()
        }
    }
    
    func resetActivityCheck() {
        hasStepsSinceConnect = false
    }
    
    func checkForInactivity() {
        let inactivity = settings.inactivitySettings
        guard settings.watchNotificationsEnabled, inactivity.enabled, hasStepsSinceConnect, ExerciseViewModel.shared.currentExercise == nil else { return }
        
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= inactivity.startHour && hour < inactivity.endHour else {
            lastActiveDate = Date()
            return
        }
        
        if Date().timeIntervalSince(lastActiveDate) >= TimeInterval(inactivity.minutes * 60) {
            bleWriteManager.sendNotification(AppNotification(title: NSLocalizedString("Time to Move", comment: ""), subtitle: NSLocalizedString("You've been inactive for a while. Get up and take a short walk.", comment: "")))
            
            lastActiveDate = Date()
        }
    }
}

// MARK: Sleep
extension NotificationManager {
    func checkForBedtime() {
        let schedule = SleepManager.shared.schedule
        let bedtime = settings.bedtimeSettings
        guard settings.watchNotificationsEnabled, bedtime.enabled, schedule.enabled else { return }

        let calendar = Calendar.current
        let minute = (schedule.bedtime - bedtime.minutesBefore + 1440) % 1440
        // Only send it on time, and check yesterday too in case it crosses midnight
        var reminder: Date?
        for offset in [0, -1] {
            if let day = calendar.date(byAdding: .day, value: offset, to: Date()),
               let date = calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: day),
               (date..<date.addingTimeInterval(thirtyMinutes)).contains(Date()) {
                reminder = date
            }
        }
        // Remember which one we sent, since after midnight it's a new day
        guard let reminder, UserDefaults.standard.double(forKey: "lastBedtimeReminder") != reminder.timeIntervalSince1970 else { return }

        // Bedtimes after midnight count for the day before
        let bedtimeDate = reminder.addingTimeInterval(TimeInterval(bedtime.minutesBefore * 60))
        guard let night = calendar.date(byAdding: .hour, value: -12, to: bedtimeDate), schedule.days.contains(calendar.component(.weekday, from: night)) else { return }

        sendGoalNotification(AppNotification(title: NSLocalizedString("Bedtime", comment: ""), subtitle: NSLocalizedString("It's time to get ready for bed", comment: "")))
        UserDefaults.standard.set(reminder.timeIntervalSince1970, forKey: "lastBedtimeReminder")
    }
}

// MARK: Goals
extension NotificationManager {
    private func notifiedToday(_ key: String) -> Bool {
        Calendar.current.isDateInToday(Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: key)))
    }
    private func markNotifiedToday(_ key: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
    }
    
    private func sendGoalNotification(_ notif: AppNotification) {
        if !bleManager.ancsAuthorized {
            bleWriteManager.sendNotification(notif)
        }
        sendNotificationToHost(notif)
    }
    
    private func previousDailySteps() -> [Date: Int] {
        guard let deviceId = DeviceManager.shared.pairedDeviceID else { return [:] }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let key = "\(deviceId)-\(today.timeIntervalSince1970)"
        if let previousStepsCache, previousStepsCache.key == key {
            return previousStepsCache.steps
        }
        
        var steps = [Date: Int]()
        for point in ChartManager.shared.stepPoints(predicate: NSPredicate(format: "deviceId == %@ AND timestamp < %@", deviceId, today as NSDate)) {
            guard let timestamp = point.timestamp else { continue }
            steps[calendar.startOfDay(for: timestamp), default: 0] += Int(point.steps)
        }
        previousStepsCache = (key, steps)
        return steps
    }
    
    func checkStepGoals(steps: Int, goal: Int) {
        let goalSettings = settings.goalSettings
        guard settings.watchNotificationsEnabled, goal > 0 else { return }
        
        if goalSettings.halfwayReminderEnabled && steps >= goal / 2 && steps < goal && !notifiedToday("lastStepHalfwayNotified") {
            sendGoalNotification(AppNotification(title: NSLocalizedString("Halfway There", comment: ""), subtitle: NSLocalizedString("You're halfway to your step goal", comment: "")))
            markNotifiedToday("lastStepHalfwayNotified")
        }
        
        let needsGoal = goalSettings.stepReminderEnabled && !notifiedToday("lastStepGoalNotified")
        let needsRecord = goalSettings.recordReminderEnabled && !notifiedToday("lastStepRecordNotified")
        guard steps >= goal, needsGoal || needsRecord else { return }
        let previous = previousDailySteps()
        
        if needsGoal {
            let calendar = Calendar.current
            var streak = 1
            var day = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!
            while (previous[day] ?? 0) >= goal {
                streak += 1
                day = calendar.date(byAdding: .day, value: -1, to: day)!
            }
            
            if goalSettings.streakReminderEnabled && streak >= 2 {
                sendGoalNotification(AppNotification(title: String(format: NSLocalizedString("%d Day Streak", comment: ""), streak), subtitle: String(format: NSLocalizedString("You've reached your step goal %d days in a row", comment: ""), streak)))
            } else {
                sendGoalNotification(AppNotification(title: NSLocalizedString("Goal Reached", comment: ""), subtitle: NSLocalizedString("You've reached your step goal", comment: "")))
            }
            markNotifiedToday("lastStepGoalNotified")
        }
        
        // Need a week of history, otherwise every early day is a record
        if needsRecord, previous.count >= 7, let record = previous.values.max(), steps > record {
            sendGoalNotification(AppNotification(title: NSLocalizedString("New Record", comment: ""), subtitle: NSLocalizedString("You've taken more steps today than on any other day", comment: "")))
            markNotifiedToday("lastStepRecordNotified")
        }
    }
}
