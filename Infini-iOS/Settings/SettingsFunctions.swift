//
//  SettingsFunctions.swift
//  Infini-iOS
//
//  Created by xan-m on 8/15/21.
//  
//
    

import Foundation

class SettingsFunctions {
	func batteryNotification(bat: Int, bleManager: BLEManager) {
		if bat == 20 {
			print("test")
			bleManager.sendNotification(notification: "Battery at 20%")
		}
	}
}
