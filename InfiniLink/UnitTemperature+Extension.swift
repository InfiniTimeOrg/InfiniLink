//
//  UnitTemperature+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/16/24.
//

import Foundation

extension UnitTemperature {
    static var current: UnitTemperature {
        let measureFormatter = MeasurementFormatter()
        let measurement = Measurement(value: 0, unit: UnitTemperature.celsius)
        let output = measureFormatter.string(from: measurement)
        return output == "0°C" ? .celsius : .fahrenheit
    }
}
