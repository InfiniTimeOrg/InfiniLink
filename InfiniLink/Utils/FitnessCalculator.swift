//
//  FitnessCalculator.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import Foundation

class FitnessCalculator {
    let personalizationController = PersonalizationController.shared
    let bleManager = BLEManager.shared
    
    func calculateDistance(steps: Int) -> Double {
        let avgStrideRatio = 0.413
        let height = personalizationController.calculatedHeight
        let strideLength = height * avgStrideRatio * (personalizationController.gender == .male ? 1.0 : 0.9)

        var distance = strideLength * Double(steps)

        // Unit conversion
        if personalizationController.units == .imperial {
            distance /= (100.0 * 1609.34)
        } else {
            distance /= 100000
        }

        return distance
    }
    
    func calculateCaloriesBurned(steps: Int) -> Double {
        return 0.0
    }
}
