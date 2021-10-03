//
//  BLEDelegates.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/15/21.
//  
//


import Foundation
import CoreBluetooth


extension BLEManager: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else { return }
		
		for service in services {
			peripheral.discoverCharacteristics(nil, for:service)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else { return }
		
		for characteristic in characteristics {
			DeviceInfoManager().readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
			BLEDiscoveredCharacteristics().handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		DeviceInfoManager().updateInfo(characteristic: characteristic)
		BLEUpdatedCharacteristicHandler().handleUpdates(characteristic: characteristic, peripheral: peripheral)
	}
}
