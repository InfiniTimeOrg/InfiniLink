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
			// Need to grab some characteristics now, namely those that don't respond to didUpdateValueFor.
			// TODO: if AMS and ANCS are implemented, this whole switch can probably be deleted...
			switch characteristic.uuid {
				case musicControlCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
					musicChars.control = characteristic
				case musicTrackCBUUID:
					musicChars.track = characteristic
				case musicArtistCBUUID:
					// select artist characteristic for writing to music app
					musicChars.artist = characteristic
				case notifyCBUUID :
						// I'm sure there's a less clunky way to grab the full characteristic for the sendNotification() function, but this works fine for now
						notifyCharacteristic = characteristic
						if firstConnect {
							sendNotification(notification: "iOS Connected!")
							firstConnect = false
						}
				default:
					break
			}
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		switch characteristic.uuid {
		case musicControlCBUUID:
			// listen for the music controller notifications
			let musicControl = [UInt8](characteristic.value!)
			controlMusic(controlNumber: Int(musicControl[0]))
			print(musicControl)
			
		case musicTrackCBUUID:
			// select track characteristic for writing to music app
			musicChars.track = characteristic
			
		case musicArtistCBUUID:
			// select artist characteristic for writing to music app
			musicChars.artist = characteristic
			
		case hrmCBUUID:
			// subscribe to HRM, read heart rate hex, convert to decimal
			peripheral.setNotifyValue(true, for: characteristic)
			let bpm = heartRate(from: characteristic)
			heartBPM = Double(bpm)
			if bpm != 0 {
				hrmChartDataPoints.append(updateChartInfo(data: Double(bpm), heart: true))
			}
			
		case batCBUUID:
			// subscribe to battery updates, read battery hex data, convert it to decimal
			peripheral.setNotifyValue(true, for: characteristic)
			let batData = [UInt8](characteristic.value!)
			batChartDataPoints.append(updateChartInfo(data: Double(batData[0]), heart: false))
			batteryLevel = Double(batData[0])
			
			
		case timeCBUUID:
			// convert string with hex value of time to actual hex data, then write to PineTime
			peripheral.writeValue(currentTime().hexData, for: characteristic, type: .withResponse)
			
		case firmwareCBUUID:
			firmwareVersion = String(decoding: characteristic.value!, as: UTF8.self)
		default:
			break
		}
	}
}
