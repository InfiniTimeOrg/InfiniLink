//
//  SettingsFunctions.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/15/21.
//  
//
    

import Foundation

class BatteryNotifications: ObservableObject {
	
	@Published var twenty: Bool = false
	@Published var ten: Bool = false
	
	func notify(bat: Int, bleManager: BLEManager) {
		let bleWriteManger = BLEWriteManager()
		if UserDefaults.standard.object(forKey: "batteryNotification") as! Bool? == true{
			if bat > 20 {
				twenty = false
				ten = false
			} else if (bat <= 20 && bat > 10) && twenty == false {
                bleWriteManger.sendNotification(title: "Low Battery", body: "\(bat)% battery remaining")
				twenty = true
			} else if (bat <= 10 && bat > 5) && ten == false {
                bleWriteManger.sendNotification(title: "Low Battery", body: "\(bat)% battery remaining")
				ten = true
			}
		}
	}
}
