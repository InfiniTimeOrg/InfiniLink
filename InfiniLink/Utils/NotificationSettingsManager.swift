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
    
    var transliterationEnabled = true
    
    var batterySettings = BatterySettings()
    var heartSettings = HeartSettings()
    var goalSettings = GoalSettings()
}

struct GoalSettings: Codable {
    var stepReminderEnabled = true
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
