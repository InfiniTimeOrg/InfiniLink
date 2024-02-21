//
//  Notifications.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/8/21.
//

import Foundation
import CoreBluetooth

struct BLEWriteManager {
    let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
    
    func writeToMusicApp(message: String, characteristic: CBCharacteristic) -> Void {
        guard let writeData = message.data(using: .ascii) else {
            // TODO: for music app, this sends an empty string to not display anything if this is non-ascii. This string can be changed to a "cannot display song title" or whatever but that seems a lot more annoying than just displaying nothing.
            bleManager.infiniTime.writeValue("".data(using: .ascii)!, for: characteristic, type: .withResponse)
            return
        }
        bleManager.infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
    }
    
    func writeHexToMusicApp(message: [UInt8], characteristic: CBCharacteristic) -> Void {
        let writeData = Data(bytes: message, count: message.capacity)
        bleManager.infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
    }
    
    func sendNotification(title: String, body: String) {
        guard let titleData = ("   " + title + "\0").data(using: .ascii) else {
            DebugLogManager.shared.debug(error: "Failed to convert notification title to ASCII. Title: '\(title)'", log: .app, date: Date())
            return }
        guard let bodyData = (body + "\0").data(using: .ascii) else {
            DebugLogManager.shared.debug(error: "Failed to convert notification body to ASCII. Body: '\(body)'", log: .app, date: Date())
            return }
        var notification = titleData
        notification.append(bodyData)
        let doSend = UserDefaults.standard.object(forKey: "watchNotifications")
        if !notification.isEmpty {
            if (doSend == nil || doSend as! Bool) && bleManager.infiniTime != nil {
                bleManager.infiniTime.writeValue(notification, for: bleManagerVal.notifyCharacteristic, type: .withResponse)
            }
        }
    }
    
    func sendLostNotification() {
        let hexPrefix = Data([0x03, 0x01, 0x00]) // Hexadecimal representation of "\x03\x01\x00"
        let nameData = "InfiniLink".data(using: .ascii) ?? Data()

        let notification = hexPrefix + nameData

        let doSend = UserDefaults.standard.object(forKey: "watchNotifications")
        
        if notification.count > 0 {
            if (doSend == nil || doSend as! Bool) && bleManager.infiniTime != nil {
                bleManager.infiniTime.writeValue(notification, for: bleManagerVal.notifyCharacteristic, type: .withResponse)
            }
        }
    }
    
    func writeCurrentWeatherData(currentTemperature: Double, minimumTemperature: Double, maximumTemperature: Double, location: String, icon: UInt8)  {
        var bytes : [UInt8] = [0, 0] // Message Type and Message Version
        bytes.append(contentsOf: timeSince1970())
        bytes.append(contentsOf: convertTemperature(value: Int(round(currentTemperature)))) // Current temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(minimumTemperature)))) // Minimum temperature
        bytes.append(contentsOf: convertTemperature(value: Int(round(maximumTemperature)))) // Maximum temperature
        
        guard var locationData = location.data(using: .ascii) else {
            print("Weather Location String Failed!")
            for _ in 1...32 {bytes.append(0)}
            bytes.append(icon)
            
            let writeData = Data(bytes: bytes as [UInt8], count: 49)
            if bleManagerVal.weatherCharacteristic != nil {
                bleManager.infiniTime.writeValue(writeData, for: bleManagerVal.weatherCharacteristic, type: .withResponse)
            }
            return
        }
        
        if locationData.count > 32 {
            print("Weather Location String is to Big!")
            for _ in 1...32 {bytes.append(0)}
        } else {
            for _ in 1...32-locationData.count {locationData.append(0)}
            bytes.append(contentsOf: locationData)
        }
        bytes.append(icon)
        
        let writeData = Data(bytes: bytes as [UInt8], count: 49)
        if bleManagerVal.weatherCharacteristic != nil {
            bleManager.infiniTime.writeValue(writeData, for: bleManagerVal.weatherCharacteristic, type: .withResponse)
        }
    }
    
    func writeForecastWeatherData(minimumTemperature: [Double], maximumTemperature: [Double], icon: [UInt8])  {
        if (minimumTemperature.count + maximumTemperature.count + icon.count) / 3 != minimumTemperature.count && minimumTemperature.count <= 5 && minimumTemperature.count > 1 {
            print("Forecast Data Arrays Do Not Match |or| Forecast Larger Then 5 Days |or| Forecast Data is Empty")
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
        
        if bleManagerVal.weatherCharacteristic != nil {
            bleManager.infiniTime.writeValue(writeData, for: bleManagerVal.weatherCharacteristic, type: .withResponse)
        }
    }
    
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
