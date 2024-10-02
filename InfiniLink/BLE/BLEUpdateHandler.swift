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
    @ObservedObject var healthKitManager = HealthKitManager.shared
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)], predicate: NSPredicate(format: "chart == 0"))
    private var chartPoints: FetchedResults<ChartDataPoint>
    
    let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
    let weatherController = WeatherController()
    let ble_fs = BLEFSHandler.shared
    
    @AppStorage("filterHRMValues") var filterHRM: Bool = false
    @AppStorage("lastHRMValueTimestamp") var lastHRMValueTimestamp: Double = 0
    
    // function to translate heart rate to decimal, copied straight up from this tut: https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-014
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
        weatherController.updateWeatherData(ignoreTimeLimits: false)
        
        switch characteristic.uuid {
        case bleManagerVal.cbuuidList.musicControl:
            let musicControl = [UInt8](characteristic.value!)
            MusicController.shared.controlMusic(controlNumber: Int(musicControl[0]))
        case bleManagerVal.cbuuidList.hrm:
            let bpm = heartRate(from: characteristic)
            let dataPoints = ChartManager.shared.convert(results: chartPoints)
            let lastDataPoint = dataPoints.last
            
            bleManagerVal.heartBPM = Double(bpm)
            
            if bpm != 0 {
                let currentTime = Date().timeIntervalSince1970
                let timeDifference = currentTime - lastHRMValueTimestamp
                
                if let referenceValue = lastDataPoint?.value, filterHRM && (bpm > 40 && bpm < 210) {
                    let isWithinRange = abs(referenceValue - bleManagerVal.heartBPM) <= 25
                    
                    if isWithinRange {
                        updateHeartRate(bpm: bpm)
                    } else {
                        if timeDifference <= 10 {
                            updateHeartRate(bpm: bpm)
                        } else {
                            print("Abnormal value, should be filtered")
                        }
                    }
                } else {
                    updateHeartRate(bpm: bpm)
                }
            }
        case bleManagerVal.cbuuidList.bat:
            guard let value = characteristic.value else {
                DebugLogManager.shared.debug(error: "Could not read battery level", log: .ble, date: Date())
                break
            }
            let batData = [UInt8](value)
            DebugLogManager.shared.debug(error: "battery level report: \(String(batData[0]))", log: .ble, date: Date())
            ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(batData[0]), chart: ChartsAsInts.battery.rawValue))
            bleManager.batteryLevel = Double(batData[0])
        case bleManagerVal.cbuuidList.stepCount:
            guard let value = characteristic.value else {
                DebugLogManager.shared.debug(error: "Could not read step count", log: .ble, date: Date())
                break
            }
            let stepData = [UInt8](value)
            bleManagerVal.stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            healthKitManager.readCurrentSteps { value, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                let currentSteps = value
                let newSteps = Double(bleManagerVal.stepCount)
                
                let stepsToAdd = newSteps - currentSteps!
                healthKitManager.writeSteps(date: Date(), stepsToAdd: stepsToAdd)
            }
            StepCountPersistenceManager().setStepCount(steps: Int32(bleManagerVal.stepCount), arbitrary: false, date: Date())
        case bleManagerVal.cbuuidList.blefsTransfer:
            guard let value = characteristic.value else {
                DebugLogManager.shared.debug(error: "Could not read BLE FS response", log: .ble, date: Date())
                break
            }
            ble_fs.handleResponse(responseData: [UInt8](value))
        default:
            break
        }
    }
    
    func updateHeartRate(bpm: Int) {
        let currentTime = Date().timeIntervalSince1970
        lastHRMValueTimestamp = currentTime
        healthKitManager.writeHeartRate(date: Date(), dataToAdd: bleManagerVal.heartBPM)
        ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: Double(bpm), chart: ChartsAsInts.heart.rawValue))
    }
}
