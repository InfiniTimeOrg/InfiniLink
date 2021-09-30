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
		guard let titleData = ("   " + title + "\0").data(using: .ascii) else { return }
		guard let bodyData = (body + "\0").data(using: .ascii) else { return }
		var notification = titleData
		notification.append(Data(String("0x0a").hexData))
		notification.append(bodyData)
		let doSend: Bool = UserDefaults.standard.object(forKey: "watchNotifications") as? Bool ?? true
		if doSend && bleManager.isConnectedToPinetime {
			bleManager.infiniTime.writeValue(notification, for: bleManager.notifyCharacteristic, type: .withResponse)
		}
	}
}

