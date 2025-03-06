//
//  FitnessCalculator.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import Foundation

class FitnessCalculator {
    static let shared = FitnessCalculator()
    
    let personalizationController = PersonalizationController.shared
    let bleManager = BLEManager.shared
    
    func calculateDistance(steps: Int) -> Double {
        return 0.0
    }
    
    func calculateCaloriesBurned(steps: Int) -> Double {
        return 0.0
    }
}
