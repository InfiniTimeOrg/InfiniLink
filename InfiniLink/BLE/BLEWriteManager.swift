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
            // There's no title/artst, so update it with a blank string
            bleManager.infiniTime?.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
            return
        }
        bleManager.infiniTime?.writeValue(writeData, for: characteristic, type: .withResponse)
        log("Wrote to music app", type: .info, caller: "BLEWriteManager", target: .ble)
    }
    
    func writeHexToMusicApp(message: [UInt8], characteristic: CBCharacteristic) -> Void {
        guard bleManager.infiniTime != nil else { return }
        let writeData = Data(bytes: message, count: message.capacity)
        
        bleManager.infiniTime?.writeValue(writeData, for: characteristic, type: .withResponse)
        log("Wrote to music app", type: .info, caller: "BLEWriteManager", target: .ble)
    }
    
    func setTime(characteristic: CBCharacteristic) {
        guard bleManager.infiniTime != nil else { return }
        
        do {
            try bleManager.infiniTime?.writeValue(SetTime().currentTime().hexData, for: characteristic, type: .withResponse)
            log("Set watch time", type: .info, caller: "BLEWriteManager", target: .ble)
        } catch {
            bleManager.setTimeError = true
            log("Error setting watch time", caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func sendNotification(_ notif: AppNotification) {
        guard bleManager.infiniTime != nil else { return }
        
        let title = settingsManager.settings.transliterationEnabled ? notif.title.asciiSafe : notif.title
        let body = settingsManager.settings.transliterationEnabled ? notif.subtitle.asciiSafe : notif.subtitle
        
        let titleData = ("   " + title + "\0").data(using: .utf8)
        let bodyData = (body + "\0").data(using: .utf8)
        
        // Log if there was a failure when converting
        if titleData == nil {
            log("Failed to convert \(notif.title) to UTF-8 data", caller: "BLEWriteManager", target: .ble)
        }
        if bodyData == nil {
            log("Failed to convert \(notif.subtitle) to UTF-8 data", caller: "BLEWriteManager", target: .ble)
        }

        guard let title = titleData, let body = bodyData else { return } // If both of the strings couldn't be converted, don't send the notification
        
        let notification = title + body
        if let notifyCharacteristic = bleManager.notifyCharacteristic, !notification.isEmpty && settingsManager.settings.watchNotificationsEnabled {
            bleManager.infiniTime?.writeValue(notification, for: notifyCharacteristic, type: .withResponse)
            log("Notification sent with title: \(title)", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func sendLostNotification() {
        guard let infiniTime = bleManager.infiniTime, let notify = bleManager.notifyCharacteristic else { return }
        
        let hexPrefix = Data([0x03, 0x01, 0x00]) // Hexadecimal representation of "\x03\x01\x00"
        let nameData = "InfiniLink".data(using: .ascii)!
        
        let notification = hexPrefix + nameData
        
        if notification.count > 0 && settingsManager.settings.watchNotificationsEnabled {
            infiniTime.writeValue(notification, for: notify, type: .withResponse)
            log("Sent lost notification", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeCurrentWeatherData(currentTemperature: Double, minimumTemperature: Double, maximumTemperature: Double, location: String, icon: UInt8, sunrise: Date?, sunset: Date?)  {
        let sunTimesSupported = deviceManager.firmware.compare("1.16.0", options: .numeric) != .orderedAscending
        
        var bytes: [UInt8] = [0, sunTimesSupported ? 1 : 0] // Message Type and Message Version
        bytes.append(contentsOf: timeSince1970())
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
        
        let writeData = Data(bytes: bytes as [UInt8], count: sunTimesSupported ? 53 : 49)
        if let weatherChar = bleManager.weatherCharacteristic, let infiniTime = bleManager.infiniTime {
            infiniTime.writeValue(writeData, for: weatherChar, type: .withResponse)
            log("Set watch current weather", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeForecastWeatherData(minimumTemperature: [Double], maximumTemperature: [Double], icon: [UInt8])  {
        guard bleManager.infiniTime != nil else { return }
        
        if (minimumTemperature.count + maximumTemperature.count + icon.count) / 3 != minimumTemperature.count && minimumTemperature.count >= 5 && minimumTemperature.count < 1 {
            log("Forecast data arrays do not match, forecast larger than 5 days, or forecast data is empty", caller: "BLEWriteManager")
            return
        }
        
        var bytes : [UInt8] = [1, 0] // Message Type and Message Version
        bytes.append(contentsOf: timeSince1970())
        bytes.append(UInt8(minimumTemperature.count))
        
        for idx in (0...minimumTemperature.count - 1) {
            bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature[idx])))) // Minimum temperature
            bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature[idx])))) // Maximum temperature
            bytes.append(icon[idx])
        }
        
        if minimumTemperature.count < 5 {
            for _ in (0...4 - minimumTemperature.count) {
                bytes.append(contentsOf: [0, 0, 0, 0, 0])
            }
        }
        
        let writeData = Data(bytes: bytes as [UInt8], count: 36)
        
        if let weatherChar = bleManager.weatherCharacteristic, let infiniTime = bleManager.infiniTime {
            infiniTime.writeValue(writeData, for: weatherChar, type: .withResponse)
            log("Set watch forecast", type: .info, caller: "BLEWriteManager", target: .ble)
        }
    }
    
    func writeNavigationUpdate(icon: String, instructions: String, distance: String, progress: UInt8) {
        guard let infiniTime = bleManager.infiniTime else { return }
        guard let _ = bleManager.navigationFlagsCharacteristic, let nar = bleManager.navigationNarrativeCharacteristic, let dis = bleManager.navigationDistanceCharacteristic, let prog = bleManager.navigationProgressCharacteristic, let flags = bleManager.navigationFlagsCharacteristic else { return }
        
        guard let icon = icon.data(using: .ascii) else { return }
        // The narrative may contain non-InfiniTime-readable characters, so transliterate if enabled
        guard let narrative = (settingsManager.settings.transliterationEnabled ? instructions.asciiSafe : instructions).data(using: .ascii) else { return }
        guard let distance = distance.data(using: .ascii) else { return }
        
        var progress = Data()
        progress.append(progress)
        
        infiniTime.writeValue(narrative, for: nar, type: .withResponse)
        infiniTime.writeValue(distance, for: dis, type: .withResponse)
        infiniTime.writeValue(progress, for: prog, type: .withResponse)
        infiniTime.writeValue(icon, for: flags, type: .withResponse)
        
        log("Wrote navigation update", type: .info, caller: "BLEWriteManager", target: .ble)
    }
}

extension BLEWriteManager {
    private func timeSince1970() -> [UInt8] {
        let timeInterval: UInt64 = UInt64(Date().timeIntervalSince1970)
        
        let byte1 = UInt8(timeInterval & 0x00000000000000FF)
        let byte2 = UInt8((timeInterval & 0x000000000000FF00) >> 8)
        let byte3 = UInt8((timeInterval & 0x0000000000FF0000) >> 16)
        let byte4 = UInt8((timeInterval & 0x00000000FF000000) >> 24)
        let byte5 = UInt8((timeInterval & 0x000000FF00000000) >> 32)
        let byte6 = UInt8((timeInterval & 0x0000FF0000000000) >> 40)
        let byte7 = UInt8((timeInterval & 0x00FF000000000000) >> 48)
        let byte8 = UInt8((timeInterval & 0xFF00000000000000) >> 56)
        
        return [byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8]
    }
    
    private func convertTemperature(value: Int) -> [UInt8] {
        let byte1 = UInt8(value * 100 & 0x00FF)
        let byte2 = UInt8((value * 100 & 0xFF00) >> 8)
        
        return [byte1, byte2]
    }
    
    private func encodeSunTime(_ date: Date?) -> [UInt8] {
        var minutesSinceMidnight: Int16 = -1
        
        if let date {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            minutesSinceMidnight = Int16(hour * 60 + minute)
        }
        
        let value = UInt16(bitPattern: minutesSinceMidnight)
        let byte1 = UInt8(value & 0x00FF)
        let byte2 = UInt8((value & 0xFF00) >> 8)
        
        return [byte1, byte2]
    }
}
