//
//  BLEAutoconnectManager.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/24/21.
//  
//
    

import Foundation
import CoreBluetooth

struct BLEAutoconnectManager {
	static var shared = BLEAutoconnectManager()
	
	var dfu: Bool = false
	var uuid: String = String()
	
	func connect (peripheral: CBPeripheral) -> Bool {
		// handle autoconnect defaults
		let settings = UserDefaults.standard
		let autoconnect = settings.object(forKey: "autoconnect") as? Bool ?? true
		let autoconnectUUID = settings.object(forKey: "autoconnectUUID") as? String ?? ""
		
		if dfu {
			if uuid == peripheral.identifier.uuidString {
				BLEManager.shared.connect(peripheral: peripheral)
				BLEAutoconnectManager.shared.dfu = false
				BLEAutoconnectManager.shared.uuid = String()
				return true
			}
		} else {
			if autoconnect && peripheral.identifier.uuidString == autoconnectUUID {
				BLEManager.shared.connect(peripheral: peripheral)
				return true
			}
		}
		return false
	}
}
