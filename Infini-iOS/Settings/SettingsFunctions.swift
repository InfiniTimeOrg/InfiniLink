//
//  SettingsFunctions.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/15/21.
//  
//
    

import Foundation

class BatteryNotifications: ObservableObject {
	
	@Published var twenty: Bool = false
	@Published var ten: Bool = false
	
	func notify(bat: Int, bleManager: BLEManager) {
		if UserDefaults.standard.object(forKey: "batteryNotifications") as! Bool? == true{
			if bat > 20 {
				twenty = false
				ten = false
			} else if (bat <= 20 && bat > 10) && twenty == false {
				bleManager.sendNotification(notification: "Battery Low")
				twenty = true
			} else if (bat <= 10 && bat > 5) && ten == false {
				bleManager.sendNotification(notification: "Battery Low")
				ten = true
			}
		}
	}
}
