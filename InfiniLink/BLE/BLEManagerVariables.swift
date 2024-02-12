//
//  Test.swift
//  InfiniLink
//
//  Created by John Stanley on 4/10/22.
//

import Foundation
import CoreBluetooth
import SwiftUICharts
import SwiftUI


class BLEManagerVal: NSObject, ObservableObject {
    static let shared = BLEManagerVal()
    
    var notifyCharacteristic: CBCharacteristic!
    var weatherCharacteristic: CBCharacteristic!
    
    let cbuuidList = BLEManager.cbuuidList()
    var musicChars = BLEManager.musicCharacteristics()

    let settings = UserDefaults.standard
    
    struct WeatherInformation {
        var temperature : Double = 0.0
        var maxTemperature : Double = 0.0
        var minTemperature : Double = 0.0
        var icon : Int = 0
    }
    
    @Published var watchFace: Int = -1
    @Published var pineTimeStyleData: PineTimeStyleData?
    @Published var timeFormat: ClockType?
    
    @Published var weatherInformation = WeatherInformation()
    @Published var loadingWeather = true
    
    // UI flag variables
    @Published var heartBPM: Double = 0 // published var to communicate the HRM data to the UI.

    @Published var firmwareVersion: String = ""
    
    @Published var stepCount: Int = 0
    @Published var stepCountTests: Int = 0
    @Published var stepCounting: Int = 0
    
    @Published var lastWeatherUpdateNWS: Int = 0
    @Published var lastWeatherUpdateWAPI: Int = 0
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0

    // Selecting and connecting variables
    @Published var deviceToConnect: Int! // When the user selects a device from the UI, that peripheral's ID goes in this var, which is passed to the peripheralDictionary
    @Published var autoconnectPeripheral: CBPeripheral!

    var batChartReconnect: Bool = true // skip first HRM transmission on every fresh connection to prevent saving of BS data
}
