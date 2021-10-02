//
//  BLESubscription Manager.swift
//  Infini-iOS
//
//  Created by Alex Emry on 10/1/21.
//  
//
    

import CoreBluetooth

struct BLEDiscoveredCharacteristics {
	let bleManager = BLEManager.shared
	func handleDiscoveredCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
		
		switch characteristic.uuid {
		case bleManager.cbuuidList.musicControl:
			peripheral.setNotifyValue(true, for: characteristic)
			bleManager.musicChars.control = characteristic
		case bleManager.cbuuidList.musicTrack:
			bleManager.musicChars.track = characteristic
		case bleManager.cbuuidList.musicArtist:
			bleManager.musicChars.artist = characteristic
		case bleManager.cbuuidList.hrm:
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.bat:
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.notify:
			bleManager.notifyCharacteristic = characteristic
			if bleManager.firstConnect {
				BLEWriteManager.init().sendNotification(title: "", body: "iOS Connected!")
				bleManager.firstConnect = false
			}
		default:
			break
		}
	}
}
