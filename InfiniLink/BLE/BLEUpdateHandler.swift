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
    let chartManager = ChartManager.shared
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    @AppStorage("filterHeartRateData") var filterHeartRateData: Bool = false
    @AppStorage("lastHeartRateUpdateTimestamp") var lastHeartRateUpdateTimestamp: Double = 0
    @AppStorage("lastTimeCheckCompleted") var lastTimeCheckCompleted: Double = 0
    
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
            
            if bpm > 0 {
                let currentTime = Date().timeIntervalSince1970
                let timeDifference = currentTime - lastHeartRateUpdateTimestamp
                
                // Check if the last data point is available and if filtering is enabled
                if let referenceValue = heartPoints.last?.value, filterHeartRateData {
                    let isWithinRange = abs(referenceValue - bleManager.heartRate) <= 25
                    
                    // Update heart rate if within the valid range or recent enough
                    if isWithinRange || timeDifference <= 10 {
                        updateHeartRate(bpm: bpm)
                    } else {
                        print("Abnormal value, should be filtered")
                    }
                } else {
                    // If no last data point or filtering is not applied, update heart rate
                    updateHeartRate(bpm: bpm)
                }
            }
        case bleManager.cbuuidList.bat:
            guard let value = characteristic.value else { break }
            let batData = [UInt8](value)
            
            bleManager.batteryLevel = Double(batData[0])
            bleManager.hasLoadedBatteryLevel = true
            
            chartManager.addBatteryDataPoint(batteryLevel: Double(batData[0]), time: Date())
        case bleManager.cbuuidList.stepCount:
            guard let value = characteristic.value else { break }
            let stepData = [UInt8](value)
            
            bleManager.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            
            if bleManager.stepCount != 0 {
                healthKitManager.readCurrentSteps { value, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    let currentSteps = value ?? 0.0
                    let newSteps = Double(bleManager.stepCount)
                    
                    let stepsToAdd = max(newSteps - currentSteps, 0) // Prevent negative steps
                    healthKitManager.writeSteps(date: Date(), stepsToAdd: stepsToAdd)
                }
                
                StepCountManager.shared.setStepCount(steps: Int32(bleManager.stepCount), isArbitrary: false, for: Date())
            }
        case bleManager.cbuuidList.blefsTransfer:
            guard let value = characteristic.value else { break }
            
            ble_fs.handleResponse(responseData: [UInt8](value))
        case bleManager.cbuuidList.motion:
            // As of now, we don't need the motion data, but it constantly updates, so to work around iOS timer restrictions, we use this to fetch data in the background
            let currentTime = Date().timeIntervalSince1970
            let timeDifference = currentTime - lastTimeCheckCompleted
            
            // Only update every five seconds
            // TODO: adjust update interval if needed
            if timeDifference > 5 {
                RemindersManager.shared.checkForDueReminders(date: Date())
                
                lastTimeCheckCompleted = Date().timeIntervalSince1970
            }
        default:
            break
        }
    }
    
    private func updateHeartRate(bpm: Int) {
        lastHeartRateUpdateTimestamp = Date().timeIntervalSince1970
        healthKitManager.writeHeartRate(date: Date(), dataToAdd: bleManager.heartRate)
        chartManager.addHeartRateDataPoint(heartRate: Double(bpm), time: Date())
    }
}
