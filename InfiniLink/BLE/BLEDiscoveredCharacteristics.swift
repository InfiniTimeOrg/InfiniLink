//
//  BLEDiscoveredCharacteristics.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/3/25.
//
//

import CoreBluetooth
import UIKit
import SwiftUI

struct BLEDiscoveredCharacteristics {
	let bleManager = BLEManager.shared
    
	func handleDiscoveredCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
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
		case bleManager.cbuuidList.hrm:
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.bat:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
        case bleManager.cbuuidList.motion:
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        case bleManager.cbuuidList.blefsTransfer:
            bleManager.blefsTransfer = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.notify:
            bleManager.notifyCharacteristic = characteristic
		case bleManager.cbuuidList.stepCount:
			peripheral.readValue(for: characteristic)
			peripheral.setNotifyValue(true, for: characteristic)
		case bleManager.cbuuidList.time:
            bleManager.currentTimeService = characteristic
            BLEWriteManager().setTime(characteristic: characteristic)
        case bleManager.cbuuidList.weather:
            bleManager.weatherCharacteristic = characteristic
            
        case bleManager.cbuuidList.navigationFlags:
            bleManager.navigationFlagsCharacteristic = characteristic
        case bleManager.cbuuidList.navigationNarrative:
            bleManager.navigationNarrativeCharacteristic = characteristic
        case bleManager.cbuuidList.navigationDistance:
            bleManager.navigationDistanceCharacteristic = characteristic
        case bleManager.cbuuidList.navigationProgress:
            bleManager.navigationProgressCharacteristic = characteristic
            
        case bleManager.cbuuidList.sleep:
            peripheral.setNotifyValue(true, for: characteristic)
		default:
			break
		}
	}
}
