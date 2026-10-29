//
//  NotificationSettingsManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/12/26.
//

import SwiftUI

struct NotificationSettings: Codable {
    var watchNotificationsEnabled = true

    var waterReminderEnabled = true
    var waterReminderAmount = 7

    var inactivitySettings = InactivitySettings()
    var bedtimeSettings = BedtimeSettings()

    var transliterationEnabled = true

    var batterySettings = BatterySettings()
    var heartSettings = HeartSettings()
    var goalSettings = GoalSettings()
    var exerciseSettings = ExerciseSettings()

    init() {}

    // Fall back to defaults for missing keys so adding a setting doesn't wipe a user's saved config on upgrade
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? container.decode(T.self, forKey: key)) ?? fallback
        }
        watchNotificationsEnabled = value(.watchNotificationsEnabled, watchNotificationsEnabled)
        waterReminderEnabled = value(.waterReminderEnabled, waterReminderEnabled)
        waterReminderAmount = value(.waterReminderAmount, waterReminderAmount)
        inactivitySettings = value(.inactivitySettings, inactivitySettings)
        bedtimeSettings = value(.bedtimeSettings, bedtimeSettings)
        transliterationEnabled = value(.transliterationEnabled, transliterationEnabled)
        batterySettings = value(.batterySettings, batterySettings)
        heartSettings = value(.heartSettings, heartSettings)
        goalSettings = value(.goalSettings, goalSettings)
        exerciseSettings = value(.exerciseSettings, exerciseSettings)
    }
}

struct InactivitySettings: Codable {
    var enabled = false
    var minutes = 60
    var startHour = 9
    var endHour = 21
}

struct BedtimeSettings: Codable {
    var enabled = true
    var minutesBefore = 30
}

struct GoalSettings: Codable {
    var stepReminderEnabled = true
    var halfwayReminderEnabled = false
    var streakReminderEnabled = true
    var recordReminderEnabled = true
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stepReminderEnabled = (try? container.decode(Bool.self, forKey: .stepReminderEnabled)) ?? stepReminderEnabled
        halfwayReminderEnabled = (try? container.decode(Bool.self, forKey: .halfwayReminderEnabled)) ?? halfwayReminderEnabled
        streakReminderEnabled = (try? container.decode(Bool.self, forKey: .streakReminderEnabled)) ?? streakReminderEnabled
        recordReminderEnabled = (try? container.decode(Bool.self, forKey: .recordReminderEnabled)) ?? recordReminderEnabled
    }
}

struct ExerciseSettings: Codable {
    var watchHapticsEnabled = true
}

struct HeartSettings: Codable {
    var rangeReminderEnabled = false
    var minRange = 40
    var maxRange = 200
}

struct BatterySettings: Codable {
    var lowBattery = BatteryNotificationSettings(iphone: .init(sendToiPhone: false, sendToWatch: true), watch: .init(sendToiPhone: true, sendToWatch: true))
    var fullBattery = BatteryNotificationSettings(iphone: .init(sendToiPhone: false, sendToWatch: true), watch: .init(sendToiPhone: true, sendToWatch: false))
    
    var customNotificationEnabled = false
    var customNotificationPercentage = 50.0
    var customNotificationSettings = NotifySettings()
}

struct BatteryNotificationSettings: Codable {
    var iphone = NotifySettings()
    var watch = NotifySettings()
    
    var enabled: Bool {
        iphone.sendToWatch || iphone.sendToiPhone || watch.sendToWatch || watch.sendToiPhone
    }
}

struct NotifySettings: Codable {
    var sendToiPhone = true
    var sendToWatch = true
}

final class NotificationSettingsManager: ObservableObject {
    static let shared = NotificationSettingsManager()
    
    @Published var settings: NotificationSettings {
        didSet {
            save()
        }
    }
    
    private let key = "notificationSettings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            settings = decoded
        } else {
            settings = NotificationSettings()
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
