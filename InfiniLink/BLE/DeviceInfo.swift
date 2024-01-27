//
//  DeviceInfo.swift
//  DeviceInfo
//
//  Created by Alex Emry on 9/21/21.
//

import Foundation
import CoreBluetooth

class BLEDeviceInfo: ObservableObject {
	static var shared = BLEDeviceInfo()
	var deviceName = ""
	var modelNumber = ""
	var serial = ""
	var firmware = ""
	var hardwareRevision = ""
	var softwareRevision = ""
	var manufacturer = ""
    var blefsVersion = ""
}

struct DeviceInfoManager {
	
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
	
	func updateInfo(characteristic: CBCharacteristic) {
		guard let value = characteristic.value else { return }
		
		switch characteristic.uuid {
		case cbuuids.modelNumber:
			BLEDeviceInfo.shared.modelNumber = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.serial:
			BLEDeviceInfo.shared.serial = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.firmware:
			BLEDeviceInfo.shared.firmware = String(data: value, encoding: .utf8) ?? ""
            DownloadManager.shared.updateAvailable = DownloadManager.shared.checkForUpdates(currentVersion: BLEDeviceInfo.shared.firmware)
		case cbuuids.hardwareRevision:
			BLEDeviceInfo.shared.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.softwareRevision:
			BLEDeviceInfo.shared.softwareRevision = String(data: value, encoding: .utf8) ?? ""
		case cbuuids.manufacturer:
			BLEDeviceInfo.shared.manufacturer = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.blefsVersion:
            let byteArray = [UInt8](characteristic.value!)
            BLEDeviceInfo.shared.blefsVersion = String(Int(byteArray[1])) + String(Int(byteArray[0]))
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
		let deviceNamer = DeviceNameManager()
		let deviceName = deviceNamer.getName(deviceUUID: uuid)
		
		if deviceName == "" {
			BLEDeviceInfo.shared.deviceName = "InfiniTime"
		} else {
			BLEDeviceInfo.shared.deviceName = deviceName
		}
	}
	
	func clearDeviceInfo(){
		BLEDeviceInfo.shared.deviceName = ""
		BLEDeviceInfo.shared.modelNumber = ""
		BLEDeviceInfo.shared.serial = ""
		BLEDeviceInfo.shared.firmware = ""
		BLEDeviceInfo.shared.hardwareRevision = ""
		BLEDeviceInfo.shared.softwareRevision = ""
		BLEDeviceInfo.shared.manufacturer = ""
	}
}
