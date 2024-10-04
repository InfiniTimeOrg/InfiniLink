//
//  Weather.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/4/24.
//

import Foundation

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

struct WeatherForecastDay {
    var maxTemperature: Double
    var minTemperature: Double
    var icon: UInt8
    var name: String
}
