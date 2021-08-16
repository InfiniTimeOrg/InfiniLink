//
//  BLEDelegates.swift
//  Infini-iOS
//
//  Created by xan-m on 8/15/21.
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
			if characteristic.properties.contains(.read) {
				peripheral.readValue(for: characteristic)
			}
			
			// subscribe to HRM, battery, and music control characteristics
			if characteristic.properties.contains(.notify) {
				switch characteristic.uuid {
				case musicControlCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
				case hrmCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
				case batCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
				default:
					break
				}
				peripheral.setNotifyValue(true, for: characteristic)
			}
			
			if characteristic.properties.contains(.write) {
				if characteristic.uuid == notifyCBUUID {
					// I'm sure there's a less clunky way to grab the full characteristic for the sendNotification() function, but this works fine for now
					notifyCharacteristic = characteristic
					sendNotification(notification: "iOS Connected!")
				}
			}
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		switch characteristic.uuid {
		case musicControlCBUUID:
			// listen for the music controller notifications
			musicChars.control = characteristic
			let musicControl = [UInt8](characteristic.value!)
			controlMusic(controlNumber: Int(musicControl[0]))
			
		case musicTrackCBUUID:
			// select track characteristic for writing to music app
			musicChars.track = characteristic
			
		case musicArtistCBUUID:
			// select artist characteristic for writing to music app
			musicChars.artist = characteristic
			
		case hrmCBUUID:
			// read heart rate hex, convert to decimal
			heartBPM = "Reading"
			let bpm = heartRate(from: characteristic)
			heartBPM = String(bpm)
			
		case batCBUUID:
			// read battery hex data, convert it to decimal
			batteryLevel = "Reading"
			let batData = [UInt8](characteristic.value!)
			batteryLevel = String(batData[0])
			
		case timeCBUUID:
			// convert string with hex value of time to actual hex data, then write to PineTime
			peripheral.writeValue(currentTime().hexData, for: characteristic, type: .withResponse)
			
		case firmwareCBUUID:
			firmwareVersion = "Reading"
			firmwareVersion = String(decoding: characteristic.value!, as: UTF8.self)
		default:
			break
		}
	}
}
