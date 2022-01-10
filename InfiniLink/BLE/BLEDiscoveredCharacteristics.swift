//
//  BLESubscription Manager.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/1/21.
//  
//
    

import CoreBluetooth

struct BLEDiscoveredCharacteristics {
	let bleManager = BLEManager.shared
	func handleDiscoveredCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
		
		switch characteristic.uuid {
			// music controller UUIDs
		case bleManager.cbuuidList.musicControl:
			peripheral.setNotifyValue(true, for: characteristic)
			bleManager.musicChars.control = characteristic
        case bleManager.cbuuidList.statusControl:
            bleManager.musicChars.status = characteristic
		case bleManager.cbuuidList.musicTrack:
			bleManager.musicChars.track = characteristic
		case bleManager.cbuuidList.musicArtist:
			bleManager.musicChars.artist = characteristic
        case bleManager.cbuuidList.positionTrack:
            bleManager.musicChars.position = characteristic
        case bleManager.cbuuidList.lengthTrack:
            bleManager.musicChars.length = characteristic
			//HRM and battery
		case bleManager.cbuuidList.hrm:
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.bat:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
			// ANS notifications
		case bleManager.cbuuidList.blefsTransfer:
			bleManager.blefsTransfer = characteristic
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.notify:
			bleManager.notifyCharacteristic = characteristic
			if bleManager.firstConnect {
				BLEWriteManager.init().sendNotification(title: "", body: "iOS Connected!")
				bleManager.firstConnect = false
			}
		case bleManager.cbuuidList.stepCount:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.time:
			do {
				try peripheral.writeValue(SetTime().currentTime().hexData, for: characteristic, type: .withResponse)
			} catch {
				bleManager.setTimeError = true
			}
		default:
			break
		}
	}
}
