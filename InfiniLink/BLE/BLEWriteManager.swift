//
//  BLEWriteManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/27/25.
//

import Foundation
import CoreBluetooth
import SwiftUI

struct BLEWriteManager {
    let bleManager = BLEManager.shared
    let deviceManager = DeviceManager.shared
    let settingsManager = NotificationSettingsManager.shared
    
    func writeToMusicApp(message: String, characteristic: CBCharacteristic) -> Void {
        guard bleManager.infiniTime != nil else { return }

        let message = settingsManager.settings.transliterationEnabled ? message.asciiSafe : message

        guard let writeData = message.data(using: .ascii) else {
            // InfiniTime can't show non-ASCII text, so clear the field instead
            bleManager.infiniTime?.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
            return
        }
        bleManager.infiniTime?.writeValue(writeData, for: characteristic, type: .withResponse)
        log("Wrote to music app", type: .info, caller: "BLEWriteManager", target: .ble)
    }
    
    func writeHexToMusicApp(message: [UInt8], characteristic: CBCharacteristic) -> Void {
        guard bleManager.infiniTime != nil else { return }
        bleManager.infiniTime?.writeValue(Data(message), for: characteristic, type: .withResponse)
        log("Wrote to music app", type: .info, caller: "BLEWriteManager", target: .ble)
    }
    
    func setTime(characteristic: CBCharacteristic) {
        guard bleManager.infiniTime != nil else { return }
        
        bleManager.infiniTime?.writeValue(SetTime.currentTime(), for: characteristic, type: .withResponse)
        log("Set watch time", type: .info, caller: "BLEWriteManager", target: .ble)
    }
    
    func sendNotification(_ notif: AppNotification) {
        guard bleManager.infiniTime != nil else { return }
        
        let title = settingsManager.settings.transliterationEnabled ? notif.title.asciiSafe : notif.title
        let body = settingsManager.settings.transliterationEnabled ? notif.subtitle.asciiSafe : notif.subtitle
        
        let notification = Data(("   " + title + "\0").utf8) + Data((body + "\0").utf8)
        if let notifyCharacteristic = bleManager.notifyCharacteristic, settingsManager.settings.watchNotificationsEnabled {
            bleManager.infiniTime?.writeValue(notification, for: notifyCharacteristic, type: .withResponse)
            log("Notification sent with title: \(title)", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func sendLostNotification() {
        guard let infiniTime = bleManager.infiniTime, let notify = bleManager.notifyCharacteristic else { return }
        
        let notification = Data([0x03, 0x01, 0x00]) + Data("InfiniLink".utf8)
        
        if settingsManager.settings.watchNotificationsEnabled {
            infiniTime.writeValue(notification, for: notify, type: .withResponse)
            log("Sent lost notification", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeCurrentWeatherData(currentTemperature: Double, minimumTemperature: Double, maximumTemperature: Double, location: String, icon: UInt8, sunrise: Date?, sunset: Date?)  {
        let sunTimesSupported = deviceManager.firmware.compare("1.16.0", options: .numeric) != .orderedAscending
        
        var bytes: [UInt8] = [0, sunTimesSupported ? 1 : 0] // Message Type and Message Version
        bytes.append(contentsOf: UInt64(Date().timeIntervalSince1970).littleEndianBytes)
        bytes.append(contentsOf: convertTemperature(value: Int(round(currentTemperature)))) // Current temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature)))) // Minimum temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature)))) // Maximum temperature
        
        let safeLocation = settingsManager.settings.transliterationEnabled ? location.asciiSafe : location
        var locationBytes = [UInt8]()
        if let asciiData = safeLocation.data(using: .ascii) {
            locationBytes = Array(asciiData.prefix(32))
            if asciiData.count > 32 {
                log("Weather location too long, truncated to 32 bytes", caller: "BLEWriteManager", target: .ble)
            }
        } else {
            log("Weather location has unsupported characters, sending without it", caller: "BLEWriteManager", target: .ble)
        }
        locationBytes.append(contentsOf: Array(repeating: 0, count: 32 - locationBytes.count))
        bytes.append(contentsOf: locationBytes)
        
        bytes.append(icon)
        
        if sunTimesSupported {
            bytes.append(contentsOf: encodeSunTime(sunrise))
            bytes.append(contentsOf: encodeSunTime(sunset))
        }
        
        if let weatherChar = bleManager.weatherCharacteristic, let infiniTime = bleManager.infiniTime {
            infiniTime.writeValue(Data(bytes), for: weatherChar, type: .withResponse)
            log("Set watch current weather", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeForecastWeatherData(minimumTemperature: [Double], maximumTemperature: [Double], icon: [UInt8])  {
        guard bleManager.infiniTime != nil else { return }
        
        let days = minimumTemperature.count
        guard (1...5).contains(days), maximumTemperature.count == days, icon.count == days else {
            log("Forecast data arrays do not match, forecast larger than 5 days, or forecast data is empty", caller: "BLEWriteManager")
            return
        }
        
        var bytes : [UInt8] = [1, 0] // Message Type and Message Version
        bytes.append(contentsOf: UInt64(Date().timeIntervalSince1970).littleEndianBytes)
        bytes.append(UInt8(days))
        
        for idx in 0..<days {
            bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature[idx])))) // Minimum temperature
            bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature[idx])))) // Maximum temperature
            bytes.append(icon[idx])
        }
        
        bytes.append(contentsOf: Array(repeating: 0, count: (5 - days) * 5))
        
        if let weatherChar = bleManager.weatherCharacteristic, let infiniTime = bleManager.infiniTime {
            infiniTime.writeValue(Data(bytes), for: weatherChar, type: .withResponse)
            log("Set watch forecast", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeNavigationUpdate(icon: String, instructions: String, distance: String, progress: UInt8) {
        guard let infiniTime = bleManager.infiniTime else { return }
        guard let nar = bleManager.navigationNarrativeCharacteristic, let dis = bleManager.navigationDistanceCharacteristic, let prog = bleManager.navigationProgressCharacteristic, let flags = bleManager.navigationFlagsCharacteristic else { return }
        
        guard let icon = icon.data(using: .ascii) else { return }
        // The narrative may contain non-InfiniTime-readable characters, so transliterate if enabled
        guard let narrative = (settingsManager.settings.transliterationEnabled ? instructions.asciiSafe : instructions).data(using: .ascii) else { return }
        guard let distance = distance.data(using: .ascii) else { return }
        
        infiniTime.writeValue(narrative, for: nar, type: .withResponse)
        infiniTime.writeValue(distance, for: dis, type: .withResponse)
        infiniTime.writeValue(Data([progress]), for: prog, type: .withResponse)
        infiniTime.writeValue(icon, for: flags, type: .withResponse)
        
        log("Wrote navigation update", type: .info, caller: "BLEWriteManager", target: .ble)
    }
}

extension BLEWriteManager {
    private func convertTemperature(value: Int) -> [UInt8] {
        Int16(truncatingIfNeeded: value * 100).littleEndianBytes
    }
    
    private func encodeSunTime(_ date: Date?) -> [UInt8] {
        var minutesSinceMidnight: Int16 = -1
        
        if let date {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            minutesSinceMidnight = Int16(hour * 60 + minute)
        }
        
        return minutesSinceMidnight.littleEndianBytes
    }
}
