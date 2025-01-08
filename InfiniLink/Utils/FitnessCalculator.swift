//
//  FitnessCalculator.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import Foundation

class FitnessCalculator {
    static let shared = FitnessCalculator()
    
    let personalization = PersonalizationController.shared
    let bleManager = BLEManager.shared
    
    var weight: Double {
        let avg = 55 // Average weight in kg (approx. 120 lbs)
        return Double(personalization.weight ?? avg) * 0.453592 // Convert lbs to kg
    }
    
    var height: Double {
        let avg = 153 // Average height in cm (approx. 5 ft)
        return Double(personalization.height ?? avg) / 100.0 // Convert cm to meters
    }
    
    func calculateDistance(steps: Int) -> Double {
        let stride = height * 0.414 // Calculate stride length in meters
        let distance = stride * Double(steps)
        
        if personalization.units == .metric {
            return distance / 1609.34
        } else {
            return distance
        }
    }
    
    func calculateCaloriesBurned(steps: Int) -> Double {
        let caloriesPerStep = (0.04 * weight) / 150.0
        return Double(steps) * caloriesPerStep
    }
}
