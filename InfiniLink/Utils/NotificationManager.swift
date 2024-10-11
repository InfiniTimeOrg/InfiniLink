//
//  NotificationManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import UserNotifications

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
        let notif = AppNotification(title: NSLocalizedString("Battery Low", comment: ""), subtitle: "\(bat)% " + NSLocalizedString("battery remaining", comment: ""))
        
        if UserDefaults.standard.object(forKey: "batteryNotification") as! Bool? == true && !bleManager.firstConnect {
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