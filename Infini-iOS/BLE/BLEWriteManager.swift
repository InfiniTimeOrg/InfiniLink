//
//  Notifications.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/8/21.
//

import Foundation
import CoreBluetooth

struct BLEWriteManager {
	let bleManager = BLEManager.shared
	
	func writeToMusicApp(message: String, characteristic: CBCharacteristic) -> Void {
		guard let writeData = message.data(using: .ascii) else {
			// TODO: for music app, this sends an empty string to not display anything if this is non-ascii. This string can be changed to a "cannot display song title" or whatever but that seems a lot more annoying than just displaying nothing.
			bleManager.infiniTime.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
			return
		}
		bleManager.infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
	}
	
	func sendNotification(title: String, body: String) {
		guard let titleData = ("   " + title + "\0").data(using: .ascii) else {
			DebugLogManager.shared.debug(error: nil, log: .app, additionalInfo: "Failed to convert notification title to ASCII", date: Date())
			return }
		guard let bodyData = (body + "\0").data(using: .ascii) else {
			DebugLogManager.shared.debug(error: nil, log: .app, additionalInfo: "Failed to convert notification body to ASCII", date: Date())
			return }
		var notification = titleData
		notification.append(bodyData)
		let doSend = UserDefaults.standard.object(forKey: "watchNotifications")
		if !notification.isEmpty {
			if (doSend == nil || doSend as! Bool) && bleManager.infiniTime != nil {
				bleManager.infiniTime.writeValue(notification, for: bleManager.notifyCharacteristic, type: .withResponse)
			}
		}
	}
}

