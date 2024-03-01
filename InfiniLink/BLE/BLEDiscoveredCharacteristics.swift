//
//  BLESubscription Manager.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/1/21.
//  
//
    

import CoreBluetooth
import UIKit
import SwiftUI

struct BLEDiscoveredCharacteristics {
	let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
    
    @AppStorage("sendFirstConnectNotification") var sendFirstConnectNotification: Bool = true
    
	func handleDiscoveredCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
		switch characteristic.uuid {
		case bleManagerVal.cbuuidList.musicControl:
			peripheral.setNotifyValue(true, for: characteristic)
            bleManagerVal.musicChars.control = characteristic
        case bleManagerVal.cbuuidList.statusControl:
            bleManagerVal.musicChars.status = characteristic
		case bleManagerVal.cbuuidList.musicTrack:
            bleManagerVal.musicChars.track = characteristic
		case bleManagerVal.cbuuidList.musicArtist:
            bleManagerVal.musicChars.artist = characteristic
        case bleManagerVal.cbuuidList.positionTrack:
            bleManagerVal.musicChars.position = characteristic
        case bleManagerVal.cbuuidList.lengthTrack:
            bleManagerVal.musicChars.length = characteristic
		case bleManagerVal.cbuuidList.hrm:
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManagerVal.cbuuidList.bat:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
        case bleManagerVal.cbuuidList.blefsTransfer:
            bleManager.blefsTransfer = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
		case bleManagerVal.cbuuidList.notify:
            bleManagerVal.notifyCharacteristic = characteristic
			if bleManager.firstConnect && sendFirstConnectNotification {
                BLEWriteManager.init().sendNotification(title: "", body: "\(UIDevice.current.name) Connected!")
                bleManager.firstConnect = false
			}
		case bleManagerVal.cbuuidList.stepCount:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManagerVal.cbuuidList.time:
            bleManager.currentTimeService = characteristic
            BLEWriteManager.init().setTime(characteristic: characteristic)
        case bleManagerVal.cbuuidList.weather:
            bleManagerVal.weatherCharacteristic = characteristic
		default:
			break
		}
	}
}
