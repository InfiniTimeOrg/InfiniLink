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
    let healthKitManager = HealthKitManager.shared
    
    @AppStorage("filterHeartRateData") var filterHeartRateData: Bool = false
    @AppStorage("lastHeartRateUpdateTimestamp") var lastHeartRateUpdateTimestamp: Double = 0
    
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
//            let dataPoints = ChartManager.shared.convert(results: chartPoints)
//            let lastDataPoint = dataPoints.last
            
            bleManager.heartRate = Double(bpm)
            
            if bpm != 0 {
                let currentTime = Date().timeIntervalSince1970
//                let timeDifference = currentTime - lastHeartRateUpdateTimestamp
                
                // TODO: update filter logic
//                if let referenceValue = lastDataPoint?.value, filterHeartRateData && (bpm > 40 && bpm < 210) {
//                    let isWithinRange = abs(referenceValue - bleManager.heartRate) <= 25
//                    
//                    if isWithinRange {
//                        updateHeartRate(bpm: bpm)
//                    } else {
//                        if timeDifference <= 10 {
//                            updateHeartRate(bpm: bpm)
//                        } else {
//                            print("Abnormal value, should be filtered")
//                        }
//                    }
//                } else {
//                    updateHeartRate(bpm: bpm)
//                }
                updateHeartRate(bpm: bpm)
            }
        case bleManager.cbuuidList.bat:
            guard let value = characteristic.value else { break }
            let batData = [UInt8](value)
            
            bleManager.batteryLevel = Double(batData[0])
        case bleManager.cbuuidList.stepCount:
            guard let value = characteristic.value else { break }
            let stepData = [UInt8](value)
            
            bleManager.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            healthKitManager.readCurrentSteps { value, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                let currentSteps = value
                let newSteps = Double(bleManager.stepCount)
                
                let stepsToAdd = newSteps - currentSteps!
                healthKitManager.writeSteps(date: Date(), stepsToAdd: stepsToAdd)
            }
        case bleManager.cbuuidList.blefsTransfer:
            guard let value = characteristic.value else { break }
            ble_fs.handleResponse(responseData: [UInt8](value))
        default:
            break
        }
    }
    
    private func updateHeartRate(bpm: Int) {
        let currentTime = Date().timeIntervalSince1970
        lastHeartRateUpdateTimestamp = currentTime
        healthKitManager.writeHeartRate(date: Date(), dataToAdd: bleManager.heartRate)
//        ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(bpm), chart: ChartsAsInts.heart.rawValue))
    }
}
