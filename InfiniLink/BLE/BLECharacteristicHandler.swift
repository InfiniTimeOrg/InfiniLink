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
    static let shared = BLECharacteristicHandler()
    
    let bleFs = BLEFSHandler.shared
    let bleManager = BLEManager.shared
    let healthKitManager = HealthKitManager.shared
    let chartManager = ChartManager.shared
    let notificationManager = NotificationManager.shared
    let deviceManager = DeviceManager.shared
    let weatherController = WeatherController.shared
    let persistenceController = PersistenceController.shared
    let stepCountManager = StepCountManager.shared
    let motionController = MotionController.shared
    let fitnessCalculator = FitnessCalculator()
    
    @AppStorage("filterHeartRateData") var filterHeartRateData = true
    
    @AppStorage("lastHeartRateUpdateTimestamp") var lastHeartRateUpdateTimestamp: Double = 0
    @AppStorage("lastHeartRateValue") var lastHeartRateValue = 0
    @AppStorage("lastTimeCheckCompleted") var lastTimeCheckCompleted: Double = 0
    @AppStorage("lastStatsSyncTimestamp") var lastStatsSyncTimestamp: Double = 0

    @AppStorage("healthKitLastRawStepCount") var healthKitLastRawStepCount = -1
    @AppStorage("healthKitLastRawStepDay") var healthKitLastRawStepDay: Double = 0

    @AppStorage("healthKitLastSyncedKcal") var healthKitLastSyncedKcal: Double = -1
    @AppStorage("healthKitLastKcalDay") var healthKitLastKcalDay: Double = 0
    
    func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        guard byteArray.count >= 2 else { return -1 }
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is little-endian in the 2nd and 3rd bytes
            guard byteArray.count >= 3 else { return -1 }
            return Int(byteArray[1]) + (Int(byteArray[2]) << 8)
        }
    }
    
    func handleDiscoveredCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case BLEUUID.musicControl:
            peripheral.setNotifyValue(true, for: characteristic)
            bleManager.musicChars.control = characteristic
        case BLEUUID.statusControl:
            bleManager.musicChars.status = characteristic
        case BLEUUID.musicTrack:
            bleManager.musicChars.track = characteristic
        case BLEUUID.musicArtist:
            bleManager.musicChars.artist = characteristic
        case BLEUUID.positionTrack:
            bleManager.musicChars.position = characteristic
        case BLEUUID.lengthTrack:
            bleManager.musicChars.length = characteristic
        case BLEUUID.hrm:
            peripheral.setNotifyValue(true, for: characteristic)
        case BLEUUID.bat:
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        case BLEUUID.motion:
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
            motionController.checkAccelerometer()
        case BLEUUID.blefsTransfer:
            bleManager.blefsTransfer = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            deviceManager.readSettingsIfNeeded()
        case BLEUUID.notify:
            bleManager.notifyCharacteristic = characteristic
        case BLEUUID.stepCount:
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        case BLEUUID.time:
            bleManager.currentTimeService = characteristic
            BLEWriteManager().setTime(characteristic: characteristic)
        case BLEUUID.weather:
            bleManager.weatherCharacteristic = characteristic
            weatherController.fetchWeatherData()
        case BLEUUID.dfuControlPoint:
            bleManager.dfuControlPointCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        case BLEUUID.dfuPacket:
            bleManager.dfuPacketCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        case BLEUUID.navigationFlags:
            bleManager.navigationFlagsCharacteristic = characteristic
        case BLEUUID.navigationNarrative:
            bleManager.navigationNarrativeCharacteristic = characteristic
        case BLEUUID.navigationDistance:
            bleManager.navigationDistanceCharacteristic = characteristic
        case BLEUUID.navigationProgress:
            bleManager.navigationProgressCharacteristic = characteristic
        default:
            break
        }
    }
    
    func handleUpdates(characteristic: CBCharacteristic) {
        switch characteristic.uuid {
        case BLEUUID.musicControl:
            guard let value = characteristic.value, let control = value.first else { break }
            
            MusicController.shared.controlMusic(controlNumber: Int(control))
        case BLEUUID.hrm:
            let bpm = heartRate(from: characteristic)
            guard bpm >= 0 else { break }
            guard bpm > 0 else {
                bleManager.heartRate = 0
                break
            }

            // Only compare against a recent reading, since heart rate can change a lot over a few minutes
            let secondsSinceLastReading = Date().timeIntervalSince1970 - lastHeartRateUpdateTimestamp
            if filterHeartRateData && secondsSinceLastReading < 60 && abs(bpm - lastHeartRateValue) > 25 {
                log("Abnormal heart rate value detected: \(bpm)", type: .info, caller: "BLECharacteristicHandler")
                break
            }

            bleManager.heartRate = Double(bpm)
            updateHeartRate(bpm: bpm)
        case BLEUUID.bat:
            guard let value = characteristic.value, !value.isEmpty else { break }
            let batData = [UInt8](value)
            
            log("Received battery value", type: .info, caller: "BLECharacteristicHandler")
            
            bleManager.batteryLevel = Double(batData[0])
            bleManager.hasLoadedBatteryLevel = true
            
            chartManager.addBatteryDataPoint(batteryLevel: Double(batData[0]), time: Date())

            notificationManager.checkToSendBatteryNotifications()
        case BLEUUID.stepCount:
            guard let value = characteristic.value, value.count >= 4 else { break }
            let stepData = [UInt8](value)
            let stepCount = Int(stepData[0]) + (Int(stepData[1]) * 256) + (Int(stepData[2]) * 65536) + (Int(stepData[3]) * 16777216)
            
            bleManager.stepCount = stepCount
            // Also on 0 so inactivity checks start after connecting
            notificationManager.updateActivity(steps: stepCount)
            if stepCount != 0 {
                syncStepsToHealthKit(rawWatchCount: stepCount)
                syncCaloriesToHealthKit(rawWatchCount: stepCount)
                stepCountManager.setStepCount(stepCount)
                ExerciseViewModel.shared.ingestWatchSteps(stepCount)
                checkForCompletedStepGoal()
            }
            syncStatsIfNeeded()
        case BLEUUID.blefsTransfer:
            guard let value = characteristic.value else { break }
            
            bleFs.handleResponse(responseData: [UInt8](value))
        case BLEUUID.motion:
            // It also constantly updates, so to work around iOS timer restrictions, we use this to fetch data in the background
            let currentTime = Date().timeIntervalSince1970
            let timeDifference = currentTime - lastTimeCheckCompleted

            if let motionData = characteristic.value, motionData.count >= 6 {
                let bytes = [UInt8](motionData)
                let x = Int16(bitPattern: UInt16(bytes[0]) | (UInt16(bytes[1]) << 8))
                let y = Int16(bitPattern: UInt16(bytes[2]) | (UInt16(bytes[3]) << 8))
                let z = Int16(bitPattern: UInt16(bytes[4]) | (UInt16(bytes[5]) << 8))

                motionController.ingest(x: x, y: y, z: z)
            }

            // Only update every five seconds
            if timeDifference > 5 {
                notificationManager.checkAndNotifyForWaterReminders()
                notificationManager.checkForInactivity()

                weatherController.checkForUpdate()

                notificationManager.checkHostBatteryState()

                SleepManager.shared.processIfNeeded()

                lastTimeCheckCompleted = Date().timeIntervalSince1970
            }

            syncStatsIfNeeded()
        default:
            break
        }
    }
    
    // The watch reports a cumulative daily step total that resets at midnight so we sync the increase since the last reading to healthkit, and rebase silently on a new day or a counter reset so the whole day doesn't get sent to healthkit in one big value
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

    // While a workout is running, its own hrm based energy covers that window so the write is skipped there, but keep the baseline advancing so nothing jumps forward
    private func syncCaloriesToHealthKit(rawWatchCount: Int) {
        let startOfToday = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let sameDay = healthKitLastKcalDay == startOfToday
        let totalKcal = Double(fitnessCalculator.calculateCaloriesBurned(steps: rawWatchCount))
        let duringWorkout = ExerciseViewModel.shared.currentExercise != nil

        if !duringWorkout && sameDay && healthKitLastSyncedKcal >= 0 && totalKcal >= healthKitLastSyncedKcal {
            healthKitManager.saveCalories(kcal: totalKcal - healthKitLastSyncedKcal)
        }

        healthKitLastSyncedKcal = totalKcal
        healthKitLastKcalDay = startOfToday
    }

    // Keep these updates triggerable by both heart and accel updates
    private func syncStatsIfNeeded() {
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastStatsSyncTimestamp > 5 else { return }
        lastStatsSyncTimestamp = currentTime

        ExerciseViewModel.shared.refreshLiveActivityInBackground()
    }

    private func checkForCompletedStepGoal() {
        notificationManager.checkStepGoals(steps: bleManager.stepCount, goal: Int(deviceManager.settings.stepsGoal))
    }
    private func updateHeartRate(bpm: Int) {
        lastHeartRateUpdateTimestamp = Date().timeIntervalSince1970
        lastHeartRateValue = bpm
        
        healthKitManager.writeHeartRate(date: Date(), dataToAdd: Double(bpm))
        chartManager.addHeartRateDataPoint(heartRate: Double(bpm), time: Date())
        ExerciseViewModel.shared.ingestHeartRate(bpm)

        notificationManager.sendHeartRangeNotification(bpm)
        syncStatsIfNeeded()
    }
}
