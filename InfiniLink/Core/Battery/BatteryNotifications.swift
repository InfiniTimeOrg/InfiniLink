//
//  BatteryNotifications.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/24.
//

import Foundation
import SwiftUI

class BatteryNotifications: ObservableObject {
    @ObservedObject var notificationManager = NotificationManager()
    @Published var twenty: Bool = false
    @Published var ten: Bool = false
    
    func notify(bat: Int, bleManager: BLEManager) {
        let bleWriteManger = BLEWriteManager()
        if UserDefaults.standard.object(forKey: "batteryNotification") as! Bool? == true{
            if bat > 20 {
                twenty = false
                ten = false
            } else if (bat <= 20 && bat > 10) && twenty == false {
                notificationManager.sendLowBatteryNotification(bat: bat)
                bleWriteManger.sendNotification(title: NSLocalizedString("battery_low", comment: ""), body: "\(bat)% " + NSLocalizedString("battery_low_message", comment: ""))
                twenty = true
            } else if (bat <= 10 && bat > 5) && ten == false {
                notificationManager.sendLowBatteryNotification(bat: bat)
                bleWriteManger.sendNotification(title: NSLocalizedString("battery_low", comment: ""), body: "\(bat)% " + NSLocalizedString("battery_low_message", comment: ""))
                ten = true
            }
        }
    }
}
