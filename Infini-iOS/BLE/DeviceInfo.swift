//
//  DeviceInfo.swift
//  DeviceInfo
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import CoreBluetooth

struct BLEDeviceInfo {
	static var shared = BLEDeviceInfo()
	var modelNumber = ""
	var serial = ""
	var firmware = ""
	var hardwareRevision = ""
	var softwareRevision = ""
	var manufacturer = ""
}

struct GetDeviceInfo {
	
	struct cbuuid {
		let modelNumber = CBUUID(string: "2A24")
		let serial = CBUUID(string: "2A25")
		let firmware = CBUUID(string: "2A26")
		let hardwareRevision = CBUUID(string: "2A27")
		let softwareRevision = CBUUID(string: "2A28")
		let manufacturer = CBUUID(string: "2A29")
	}
	let cbuuids = cbuuid()
	
	func updateInfo(characteristic: CBCharacteristic) {
		guard let value = characteristic.value else { return }
		
		switch characteristic.uuid {
		case cbuuids.modelNumber:
			BLEDeviceInfo.shared.modelNumber = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.serial:
			BLEDeviceInfo.shared.serial = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.firmware:
			BLEDeviceInfo.shared.firmware = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.hardwareRevision:
			BLEDeviceInfo.shared.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.softwareRevision:
			BLEDeviceInfo.shared.softwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.manufacturer:
			BLEDeviceInfo.shared.manufacturer = String(data: value, encoding: .utf8) ?? ""
		default:
			break
		}
	}
}
