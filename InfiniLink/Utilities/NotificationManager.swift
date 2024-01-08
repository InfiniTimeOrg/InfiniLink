//
//  NotificationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/4/24.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    func sendLowBatteryNotification(bat: Int) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("battery_low", comment: "")
        content.body = "\(bat)% " + NSLocalizedString("battery_low_message", comment: "")
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
