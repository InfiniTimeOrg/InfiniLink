//
//  DeviceInfoManager.swift
//  DeviceInfoManager
//
//  Created by Liam Willey on 10/5/24.
//

import Foundation
import CoreBluetooth
import SwiftUI

class DeviceInfoManager: ObservableObject {
	struct cbuuid {
		let modelNumber = CBUUID(string: "2A24")
		let serial = CBUUID(string: "2A25")
		let firmware = CBUUID(string: "2A26")
		let hardwareRevision = CBUUID(string: "2A27")
		let softwareRevision = CBUUID(string: "2A28")
		let manufacturer = CBUUID(string: "2A29")
        let blefsVersion = CBUUID(string: "adaf0100-4669-6c65-5472-616e73666572")
	}
	let cbuuids = cbuuid()
    
    static let shared = DeviceInfoManager()
    
    @AppStorage("deviceName") var deviceName = "InfiniTime"
    @AppStorage("modelNumber") var modelNumber = ""
    @AppStorage("serial") var serial = ""
    @AppStorage("firmware") var firmware = ""
    @AppStorage("hardwareRevision") var hardwareRevision = ""
    @AppStorage("softwareRevision") var softwareRevision = ""
    @AppStorage("manufacturer") var manufacturer = ""
    @AppStorage("blefsVersion") var blefsVersion = ""
    @AppStorage("lastDisconnect") var lastDisconnect: TimeInterval = 0
    @AppStorage("lastConnect") var lastConnect: TimeInterval = 0
	
	func updateInfo(characteristic: CBCharacteristic) {
		guard let value = characteristic.value else { return }
		
		switch characteristic.uuid {
		case cbuuids.modelNumber:
			self.modelNumber = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.serial:
			self.serial = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.firmware:
			self.firmware = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.hardwareRevision:
			self.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.softwareRevision:
			self.softwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.manufacturer:
			self.manufacturer = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.blefsVersion:
            let byteArray = [UInt8](characteristic.value!)
            self.blefsVersion = String(Int(byteArray[1])) + String(Int(byteArray[0]))
		default:
			break
		}
	}
	
	func readInfoCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
		switch characteristic.uuid {
        case cbuuids.modelNumber, cbuuids.serial, cbuuids.firmware, cbuuids.hardwareRevision, cbuuids.softwareRevision, cbuuids.manufacturer, cbuuids.blefsVersion: peripheral.readValue(for: characteristic)
		default:
			break
		}
	}
	
	func setDeviceName(uuid: String) {
        // View note in RenameView
//		let deviceNamer = DeviceNameManager()
//        let deviceName = deviceNamer.getName(for: uuid)
//		
//        self.deviceName = deviceName
	}
	
	func clearDeviceInfo() {
		self.deviceName = ""
		self.modelNumber = ""
		self.serial = ""
		self.firmware = ""
		self.hardwareRevision = ""
		self.softwareRevision = ""
		self.manufacturer = ""
	}
}
