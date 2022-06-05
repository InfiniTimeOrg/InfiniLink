//
//  BLEDelegates.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/15/21.
//  
//


import Foundation
import CoreBluetooth


extension BLEManager: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			if error != nil {
				bleLogger.debug(error: "Unable to discover services for device '\(peripheral.name!)'. Error message: \(error!)", log: .ble, date: Date())
			} else {
				bleLogger.debug(error: "Unable to discover services for device '\(peripheral.name!)'.", log: .ble, date: Date())
			}
			return
		}
		
		for service in services {
			peripheral.discoverCharacteristics(nil, for:service)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else {
			if error != nil {
				bleLogger.debug(error: "Unable to discover characteristics for device '\(peripheral.name!)'. Error message: \(error!)", log: .ble, date: Date())
			} else {
				bleLogger.debug(error: "Unable to discover characteristics for device '\(peripheral.name!)'.", log: .ble, date: Date())
			}
			return
		}
		
		for characteristic in characteristics {
			DeviceInfoManager().readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
			BLEDiscoveredCharacteristics().handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		DeviceInfoManager().updateInfo(characteristic: characteristic)
		BLEUpdatedCharacteristicHandler().handleUpdates(characteristic: characteristic, peripheral: peripheral)
		if error != nil {
			bleLogger.debug(error: "Unable to update value for device '\(peripheral.name!)'. Error message: \(error!)", log: .ble, date: Date())
		}
	}
}
