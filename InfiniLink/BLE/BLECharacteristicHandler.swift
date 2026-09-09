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

struct BLECharacteristicHandler {
    let bleFs = BLEFSHandler.shared
    let bleManager = BLEManager.shared
    let healthKitManager = HealthKitManager.shared
    let chartManager = ChartManager.shared
    let notificationManager = NotificationManager.shared
    let deviceManager = DeviceManager.shared
    let weatherController = WeatherController.shared
    let persistenceController = PersistenceController.shared
    let stepCountManager = StepCountManager.shared
    let fitnessCalculator = FitnessCalculator()
    
    @AppStorage("filterHeartRateData") var filterHeartRateData: Bool = false
    @AppStorage("remindOnStepGoalCompletion") var remindOnStepGoalCompletion = true
    @AppStorage("pauseOnWalkaway") var pauseOnWalkaway = true
    
    @AppStorage("lastHeartRateUpdateTimestamp") var lastHeartRateUpdateTimestamp: Double = 0
    @AppStorage("lastTimeCheckCompleted") var lastTimeCheckCompleted: Double = 0
    @AppStorage("lastTimeStepGoalNotified") var lastTimeStepGoalNotified: Double = 0

    @AppStorage("healthKitLastRawStepCount") var healthKitLastRawStepCount = -1
    @AppStorage("healthKitLastRawStepDay") var healthKitLastRawStepDay: Double = 0
    
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
        case bleManager.cbuuidList.dfuControlPoint:
            bleManager.dfuControlPointCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        case bleManager.cbuuidList.dfuPacket:
            bleManager.dfuPacketCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        case bleManager.cbuuidList.navigationFlags:
            bleManager.navigationFlagsCharacteristic = characteristic
        case bleManager.cbuuidList.navigationNarrative:
            bleManager.navigationNarrativeCharacteristic = characteristic
        case bleManager.cbuuidList.navigationDistance:
            bleManager.navigationDistanceCharacteristic = characteristic
        case bleManager.cbuuidList.navigationProgress:
            bleManager.navigationProgressCharacteristic = characteristic
        default:
            break
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

            guard bpm > 0 else { return }

            let currentTime = Date().timeIntervalSince1970
            let timeSinceLastUpdate = (currentTime - lastHeartRateUpdateTimestamp) / 60

            // Check if the last data point is available and if filtering is enabled
            if let lastValue = chartManager.heartPoints().last?.value, filterHeartRateData {
                let isWithinRange = abs(lastValue - bleManager.heartRate) <= 25

                // Update heart rate if within the valid range or recent enough
                if isWithinRange || timeSinceLastUpdate >= 30 {
                    updateHeartRate(bpm: bpm)
                } else {
                    log("Abnormal heart rate value detected: \(bpm)", type: .info, caller: "BLECharacteristicHandler")
                }
            } else {
                updateHeartRate(bpm: bpm)
            }
        case bleManager.cbuuidList.bat:
            guard let value = characteristic.value else { break }
            let batData = [UInt8](value)
            
            log("Received battery value", type: .info, caller: "BLECharacteristicHandler")
            
            bleManager.batteryLevel = Double(batData[0])
            bleManager.hasLoadedBatteryLevel = true
            
            chartManager.addBatteryDataPoint(batteryLevel: Double(batData[0]), time: Date())
            
            notificationManager.checkToSendBatteryNotifications()
        case bleManager.cbuuidList.stepCount:
            guard let value = characteristic.value else { break }
            let stepData = [UInt8](value)
            let stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            
            bleManager.stepCount = stepCount
            if stepCount != 0 {
                syncStepsToHealthKit(rawWatchCount: stepCount)
                stepCountManager.setStepCount(stepCount)
                checkForCompletedStepGoal()
            }
        case bleManager.cbuuidList.blefsTransfer:
            guard let value = characteristic.value else { break }
            
            bleFs.handleResponse(responseData: [UInt8](value))
        case bleManager.cbuuidList.motion:
            // As of now, we don't need the motion data, but it constantly updates, so to work around iOS timer restrictions, we use this to fetch data in the background
            let currentTime = Date().timeIntervalSince1970
            let timeDifference = currentTime - lastTimeCheckCompleted
            
            // We only need to read the rssi here (in the background) for the pause on walkway feature
            if MusicController.shared.musicPlaying == 1 && pauseOnWalkaway {
                peripheral.readRSSI()
            }
            
            // Only update every five seconds
            if timeDifference > 5 {
                notificationManager.checkAndNotifyForWaterReminders()
                
                weatherController.checkForUpdate()
                
                notificationManager.checkHostBatteryState()
                
                lastTimeCheckCompleted = Date().timeIntervalSince1970
            }
        default:
            break
        }
    }
    
    // The watch reports a cumulative daily step total that resets at midnight
    // Sync the increase since the last reading to healthkit, and rebase silently on a new day or a counter reset so a the whole day doesn't get sent to
    // healthkit in one big value
    private func syncStepsToHealthKit(rawWatchCount: Int) {
        let startOfToday = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let sameDay = healthKitLastRawStepDay == startOfToday
        let previous = healthKitLastRawStepCount

        if sameDay && previous >= 0 && rawWatchCount >= previous {
            healthKitManager.writeSteps(rawWatchCount - previous)
        }

        healthKitLastRawStepCount = rawWatchCount
        healthKitLastRawStepDay = startOfToday
    }

    private func checkForCompletedStepGoal() {
        if bleManager.stepCount >= Int(deviceManager.settings.stepsGoal) && remindOnStepGoalCompletion {
            let currentTime = Date().timeIntervalSince1970
            let twentyFourHours: TimeInterval = 86400
            
            if (currentTime - lastTimeStepGoalNotified) >= twentyFourHours {
                notificationManager.sendStepGoalReachedNotification()
                lastTimeStepGoalNotified = currentTime
            }
        }
    }
    private func updateHeartRate(bpm: Int) {
        lastHeartRateUpdateTimestamp = Date().timeIntervalSince1970
        
        healthKitManager.writeHeartRate(date: Date(), dataToAdd: bleManager.heartRate)
        chartManager.addHeartRateDataPoint(heartRate: Double(bpm), time: Date())
        
        notificationManager.sendHeartRangeNotification(bpm)
    }
}
