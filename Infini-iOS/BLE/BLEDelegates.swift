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

			
			if characteristic.properties.contains(.read) {
				peripheral.readValue(for: characteristic)
			}
			// Need to grab some characteristics now, namely those that don't respond to didUpdateValueFor.
			// TODO: if AMS and ANCS are implemented, this whole switch can probably be deleted...
			switch characteristic.uuid {
			case cbuuidList.shared.musicControl:
					peripheral.setNotifyValue(true, for: characteristic)
					musicChars.control = characteristic
			case cbuuidList.shared.musicTrack:
					musicChars.track = characteristic
			case cbuuidList.shared.musicArtist:
					// select artist characteristic for writing to music app
					musicChars.artist = characteristic
			case cbuuidList.shared.notify:
						// I'm sure there's a less clunky way to grab the full characteristic for the sendNotification() function, but this works fine for now
						notifyCharacteristic = characteristic
						if firstConnect {
							BLEWriteManager.init().sendNotification(title: "", body: "iOS Connected!")
							firstConnect = false
						}
				default:
					break
			}
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		let getDeviceInfo = DeviceInfoManager()
		getDeviceInfo.updateInfo(characteristic: characteristic)
		DownloadManager.shared.getDownloadUrls()
		
		switch characteristic.uuid {
		case cbuuidList.shared.musicControl:
			// listen for the music controller notifications
			let musicControl = [UInt8](characteristic.value!)
			controlMusic(controlNumber: Int(musicControl[0]))
			
		case cbuuidList.shared.musicTrack:
			// select track characteristic for writing to music app
			musicChars.track = characteristic
			
		case cbuuidList.shared.musicArtist:
			// select artist characteristic for writing to music app
			musicChars.artist = characteristic
			
		case cbuuidList.shared.hrm:
			// subscribe to HRM, read heart rate hex, convert to decimal
			peripheral.setNotifyValue(true, for: characteristic)
			let bpm = heartRate(from: characteristic)
			heartBPM = Double(bpm)
			if !chartReconnect {
				if bpm != 0{
					ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(bpm), chart: ChartsAsInts.heart.rawValue))
				}
			} else {
				// this skips the first HRM data point. With persistent data, every time there's an OOR condition, it copies the current HRM value, even if you've stopped the HRM. In testing I turned off the HRM, but stayed connected to the watch, and got probably 20 data points from the value the HRM was stopped at.
				
				chartReconnect = false
			}
		case cbuuidList.shared.bat:
			// subscribe to battery updates, read battery hex data, convert it to decimal
			peripheral.setNotifyValue(true, for: characteristic)
			let batData = [UInt8](characteristic.value!)
			ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(batData[0]), chart: ChartsAsInts.battery.rawValue))
			batteryLevel = Double(batData[0])
			
			
		case cbuuidList.shared.time:
			// convert string with hex value of time to actual hex data, then write to PineTime
			do {
				try peripheral.writeValue(SetTime().currentTime().hexData, for: characteristic, type: .withResponse)
			} catch SetTime.SetTimeError.nilValue {
				setTimeError = true
			} catch {
				print("Unexpected error: \(error).")
			}
			
		case cbuuidList.shared.firmware:
			firmwareVersion = String(decoding: characteristic.value!, as: UTF8.self)
		default:
			break
		}
	}
}
