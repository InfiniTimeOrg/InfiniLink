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
        var temperature: Double = 0.0
        var maxTemperature: Double = 0.0
        var minTemperature: Double = 0.0
        var icon: Int = 0
        var shortDescription: String = ""
        
        var forecastIcon: [UInt8] = []
        var forecastMaxTemperature: [Double] = []
        var forecastMinTemperature: [Double] = []
    }
    
    @Published var watchFace: Int = -1
    @Published var pineTimeStyleData: PineTimeStyleData?
    @Published var infineatWatchFace: WatchFaceInfineat?
    @Published var timeFormat: ClockType?
    
    @Published var weatherInformation = WeatherInformation()
    @Published var weatherForecastDays = [WeatherForecastDay]()
    @Published var loadingWeather = true
    
    @Published var heartBPM: Double = 0
    
    @Published var firmwareVersion: String = ""
    
    @Published var stepCount: Int = 0
    
    @Published var lastWeatherUpdateNWS: Int = 0
    @Published var lastWeatherUpdateWAPI: Int = 0
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
}

struct WeatherForecastDay {
    var maxTemperature: Double
    var minTemperature: Double
    var icon: UInt8
    var name: String
}
