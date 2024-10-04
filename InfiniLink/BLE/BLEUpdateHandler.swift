//
//  BLEUpdateHandler.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/1/21.
//
//

import CoreBluetooth
import CoreData
import SwiftUI

struct BLEUpdatedCharacteristicHandler {
    let ble_fs = BLEFSHandler.shared
    let bleManager = BLEManager.shared
    
    func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    func handleUpdates(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case bleManager.cbuuidList.musicControl:
            let musicControl = [UInt8](characteristic.value!)
            MusicController.shared.controlMusic(controlNumber: Int(musicControl[0]))
        case bleManager.cbuuidList.hrm:
            let bpm = heartRate(from: characteristic)
            
            bleManager.heartRate = Double(bpm)
        case bleManager.cbuuidList.bat:
            guard let value = characteristic.value else {
                
                break
            }
            let batData = [UInt8](value)
            
            bleManager.batteryLevel = Double(batData[0])
        case bleManager.cbuuidList.stepCount:
            guard let value = characteristic.value else {
                
                break
            }
            let stepData = [UInt8](value)
            bleManager.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
        case bleManager.cbuuidList.blefsTransfer:
            guard let value = characteristic.value else {
                
                break
            }
            ble_fs.handleResponse(responseData: [UInt8](value))
        default:
            break
        }
    }
}
