//
//  Notifications.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/8/21.
//

import Foundation
import CoreBluetooth
import SwiftUI

struct BLEWriteManager {
    let bleManager = BLEManager.shared
    
    @AppStorage("watchNotifications") var watchNotifications = true
    
    func writeToMusicApp(message: String, characteristic: CBCharacteristic) -> Void {
        guard let writeData = message.data(using: .ascii) else {
            // There's no title/artst, so update it with a blank string
            bleManager.infiniTime.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
            return
        }
        bleManager.infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
    }
    
    func writeHexToMusicApp(message: [UInt8], characteristic: CBCharacteristic) -> Void {
        let writeData = Data(bytes: message, count: message.capacity)
        bleManager.infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
    }
    
    func setTime(characteristic: CBCharacteristic) {
        do {
            try bleManager.infiniTime.writeValue(SetTime().currentTime().hexData, for: characteristic, type: .withResponse)
        } catch {
            bleManager.setTimeError = true
        }
    }
    
    func sendNotification(_ notif: AppNotification) {
        guard let titleData = ("   " + notif.title + "\0").data(using: .ascii) else { return }
        guard let bodyData = (notif.subtitle + "\0").data(using: .ascii) else { return }
        
        var notification = titleData
        
        notification.append(bodyData)
        
        if !notification.isEmpty && watchNotifications && bleManager.infiniTime != nil {
            bleManager.infiniTime.writeValue(notification, for: bleManager.notifyCharacteristic, type: .withResponse)
        }
    }
    
    func sendLostNotification() {
        let hexPrefix = Data([0x03, 0x01, 0x00]) // Hexadecimal representation of "\x03\x01\x00"
        let nameData = "InfiniLink".data(using: .ascii) ?? Data()
        
        let notification = hexPrefix + nameData
        
        if notification.count > 0 && watchNotifications && bleManager.infiniTime != nil {
            bleManager.infiniTime.writeValue(notification, for: bleManager.notifyCharacteristic, type: .withResponse)
        }
    }
    
    func writeCurrentWeatherData(currentTemperature: Double, minimumTemperature: Double, maximumTemperature: Double, location: String, icon: UInt8)  {
        var bytes : [UInt8] = [0, 0] // Message Type and Message Version
        bytes.append(contentsOf: timeSince1970())
        bytes.append(contentsOf: convertTemperature(value: Int(round(currentTemperature)))) // Current temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature)))) // Minimum temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature)))) // Maximum temperature
        
        guard var locationData = location.data(using: .ascii) else {
            log("Error encoding location string", caller: "BLEWriteManager")
            
            for _ in 1...32 {bytes.append(0)}
            bytes.append(icon)
            
            let writeData = Data(bytes: bytes as [UInt8], count: 49)
            if bleManager.weatherCharacteristic != nil {
                bleManager.infiniTime.writeValue(writeData, for: bleManager.weatherCharacteristic, type: .withResponse)
            }
            return
        }
        
        if locationData.count > 32 {
            log("Weather location string is too big to send", caller: "BLEWriteManager")
            for _ in 1...32 {bytes.append(0)}
        } else {
            for _ in 1...32-locationData.count {locationData.append(0)}
            bytes.append(contentsOf: locationData)
        }
        bytes.append(icon)
        
        let writeData = Data(bytes: bytes as [UInt8], count: 49)
        if bleManager.weatherCharacteristic != nil && bleManager.infiniTime != nil {
            bleManager.infiniTime.writeValue(writeData, for: bleManager.weatherCharacteristic, type: .withResponse)
        }
    }
    
    func writeForecastWeatherData(minimumTemperature: [Double], maximumTemperature: [Double], icon: [UInt8])  {
        if (minimumTemperature.count + maximumTemperature.count + icon.count) / 3 != minimumTemperature.count && minimumTemperature.count >= 5 && minimumTemperature.count < 1 {
            log("Forecast data arrays do not match, forecast larger than 5 days, or forecast data is empty", caller: "BLEWriteManager")
            return
        }
        
        var bytes : [UInt8] = [1, 0] // Message Type and Message Version
        bytes.append(contentsOf: timeSince1970())
        bytes.append(UInt8(minimumTemperature.count))
        
        for idx in 0...minimumTemperature.count-1 {
            bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature[idx])))) // Minimum temperature
            bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature[idx])))) // Maximum temperature
            bytes.append(icon[idx])
        }
        
        if minimumTemperature.count < 5 {
            for _ in 0...4-minimumTemperature.count {
                bytes.append(contentsOf: [0, 0, 0, 0, 0])
            }
        }
        
        let writeData = Data(bytes: bytes as [UInt8], count: 36)
        
        if bleManager.weatherCharacteristic != nil && bleManager.infiniTime != nil {
            bleManager.infiniTime.writeValue(writeData, for: bleManager.weatherCharacteristic, type: .withResponse)
        }
    }
    
    func writeNavigationUpdate() {
        guard bleManager.navigationFlagsCharacteristic != nil && bleManager.navigationNarrativeCharacteristic != nil && bleManager.navigationDistanceCharacteristic != nil && bleManager.navigationProgressCharacteristic != nil && bleManager.infiniTime != nil else { return }
        
        guard let icon = "fork".data(using: .ascii) else { return }
        guard let narrative = "At the roundabout take the first exit".data(using: .ascii) else { return }
        guard let distance = "20ft".data(using: .ascii) else { return }
        
        var progress = Data()
        progress.append(UInt8(23))
        
        bleManager.infiniTime.writeValue(narrative, for: bleManager.navigationNarrativeCharacteristic, type: .withResponse)
        bleManager.infiniTime.writeValue(distance, for: bleManager.navigationDistanceCharacteristic, type: .withResponse)
        bleManager.infiniTime.writeValue(progress, for: bleManager.navigationProgressCharacteristic, type: .withResponse)
        bleManager.infiniTime.writeValue(icon, for: bleManager.navigationFlagsCharacteristic, type: .withResponse)
    }
}

// MARK: Helper functions
extension BLEWriteManager {
    func timeSince1970() -> [UInt8] {
        let timeInterval : UInt64 = UInt64(Date().timeIntervalSince1970)
        
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
    
    func convertTemperature(value: Int) -> [UInt8] {
        let byte1 = UInt8(value * 100 & 0x00FF)
        let byte2 = UInt8((value * 100 & 0xFF00) >> 8)
        
        return [byte1, byte2]
    }
}
