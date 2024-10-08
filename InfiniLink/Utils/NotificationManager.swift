//
//  NotificationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    init() {
        if !PersonalizationController.shared.showSetupSheet {
            requestNotificationAuthorization()
        }
    }
    
    @Published var canSendNotifications = false
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.canSendNotifications = true
            } else if let error = error {
                self.canSendNotifications = false
            }
        }
    }
    
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
