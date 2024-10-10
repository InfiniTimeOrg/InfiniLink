//
//  FitnessCalculator.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import Foundation

class FitnessCalculator {
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
    
    // MET values for different paces
    enum Pace {
        case slow
        case average
        case fast
        
        var value: (speed: Double, met: Double) {
            switch self {
            case .slow:
                return (0.9, 2.8)
            case .average:
                return (1.34, 3.5)
            case .fast:
                return (1.79, 5.0)
            }
        }
    }
    
    // Calculate distance based on steps taken
    func calculateDistance(steps: Int) -> Double {
        let stride = height * 0.414 // Calculate stride length in meters
        let distance = stride * Double(steps) // Distance in meters
        return distance // Return the distance in meters
    }
    
    // Convert meters to miles
    func metersToMiles(meters: Double) -> Double {
        return meters / 1609.34 // Convert meters to miles
    }
    
    // TODO: update logic
    func calculateCaloriesBurned(steps: Int) -> Double {
        let weightInLbs = weight * 2.20462 // convert weight to lbs
        let caloriesPerStep = (0.04 * weightInLbs) / 150.0
        return Double(steps) * caloriesPerStep
    }
}
