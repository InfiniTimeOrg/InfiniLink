//
//  BLEAutoconnectManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/24/21.
//  
//
    

import Foundation
import CoreBluetooth

struct BLEAutoconnectManager {
	static var shared = BLEAutoconnectManager()
		
	func shouldDisplayConnectSheet() -> Bool {
		let bleManager = BLEManager.shared
		let autoconnect = UserDefaults.standard.object(forKey: "autoconnect") as? Bool ?? true
		let autoconnectUUID = UserDefaults.standard.object(forKey: "autoconnectUUID") as? String ?? ""
		
		if autoconnect && autoconnectUUID.isEmpty {
			return true
		} else if !autoconnect && !bleManager.isConnectedToPinetime {
			return true
		}
		return false
	}
	
	func connect (peripheral: CBPeripheral) -> Bool {
		let autoconnect = UserDefaults.standard.object(forKey: "autoconnect") as? Bool ?? true
		let autoconnectUUID = UserDefaults.standard.object(forKey: "autoconnectUUID") as? String ?? ""
		
        if autoconnect && peripheral.identifier.uuidString == autoconnectUUID && BLEManager.shared.disconnected == false {
            BLEManager.shared.connect(peripheral: peripheral)
			return true
		}
		return false
	}
}
