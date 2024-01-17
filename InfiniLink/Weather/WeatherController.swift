
//  WeatherController.swift
//  InfiniLink
//
//  Created by Jen on 1/16/24.
//

import Foundation

class WeatherController {
    static let shared = WeatherController()
    let bleWriteManager = BLEWriteManager()
    let bleManagerVal = BLEManagerVal.shared

    // This function check if the weather data should be updated. It calls the data to be updated on the watch roughly every 30 minutes. Though it's only ever checks when the watch battey percentage changes or the watch registers new steps.
    func weatherDataUpdateCheck() {
        let currentTime = Int(NSDate().timeIntervalSince1970 / 60 / 30)
        if bleManagerVal.lastWeatherUpdate == currentTime {
            return
        }
        weatherDataUpdate()
        bleManagerVal.lastWeatherUpdate = currentTime
        print("Weather Data Updated")
    }

    // This function actually updates the weather data.
    func weatherDataUpdate() {
        let randomTemp = Int.random(in: 0..<32)
        let randomIcon = UInt8.random(in: 0..<8)
        bleWriteManager.writeCurrentWeatherData(currentTemperature: randomTemp, minimumTemperature: 0, maximumTemperature: 32, location: "Astria", icon: randomIcon)
        bleWriteManager.writeForecastWeatherData(minimumTemperature: [0, 0, 0], maximumTemperature: [32, 32, 32], icon: [randomIcon, randomIcon, randomIcon])
    }
}
