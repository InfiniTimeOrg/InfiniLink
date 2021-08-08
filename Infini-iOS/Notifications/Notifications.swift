//
//  Notifications.swift
//  Infini-iOS
//
//  Created by xan-m on 8/8/21.
//

import Foundation

extension BLEManager {
	func sendNotification(notification: String) {
		// I'm pretty sure this is due to a lack of understanding on my part of the notification protocol, but sending ascii text as a notification eats the first 3 characters seemingly no matter what they are, so add 3 spaces here to absorb that, then encode the string to ASCII Data
		let paddedNotification = ("123" + notification) //.data(using: .ascii)!
		writeASCIIToPineTime(message: paddedNotification, characteristic: notifyCharacteristic)
	}
}
