//
//  FitnessCalculator.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/9/24.
//

import Foundation

enum Pace: Int {
    case verySlowWalk = 0
    case slowWalk = 1
    case avgWalk = 2
    case briskWalk = 3
    case jog = 4
    case run = 5
    case fastRun = 6
    case veryFastRun = 7

    var metValue: Double {
        switch self {
        case .verySlowWalk: return 2.0
        case .slowWalk: return 2.8
        case .avgWalk: return 3.5
        case .briskWalk: return 4.3
        case .jog: return 7.0
        case .run: return 9.8
        case .fastRun: return 11.0
        case .veryFastRun: return 13.0
        }
    }
    
    var milesPerHour: Double {
        switch self {
        case .verySlowWalk: return 1.0
        case .slowWalk: return 2.0
        case .avgWalk: return 3.0
        case .briskWalk: return 4.0
        case .jog: return 5.0
        case .run: return 6.0
        case .fastRun: return 7.5
        case .veryFastRun: return 10.0
        }
    }
}

class FitnessCalculator {
    let personalizationController = PersonalizationController.shared
    let bleManager = BLEManager.shared
    
    func strideLength(pace: Pace = .avgWalk) -> Double {
        let avgStrideRatio = personalizationController.gender == .male ? 0.415 : 0.413
        let calculatedHeight = personalizationController.calculatedHeight
        let height = personalizationController.units == .metric ? (calculatedHeight / 2.54) : (calculatedHeight) // Convert to inches
        let baseStrideLength = height * avgStrideRatio
        
        // Adjust stride length based on pace
        let strideMultiplier: Double = {
            switch pace {
            case .verySlowWalk: return 0.85
            case .slowWalk: return 0.95
            case .avgWalk: return 1.0
            case .briskWalk: return 1.1
            case .jog: return 1.25
            case .run: return 1.4
            case .fastRun: return 1.55
            case .veryFastRun: return 1.7
            }
        }()
        
        let strideLength = baseStrideLength * strideMultiplier
        return strideLength
    }
    
    func calculateDistance(steps: Int, pace: Pace = .avgWalk) -> Double {
        var distance = strideLength(pace: pace) * Double(steps)

        if personalizationController.units == .imperial {
            distance /= 63360 // Convert inches to miles
        } else {
            distance /= 39370 // Convert inches to kilometers
        }
        
        return distance
    }
    
    func stepsPerMinute(steps: Int, pace: Pace = .avgWalk) -> Int {
        let distance = calculateDistance(steps: steps, pace: pace)
        let timeMinutes = (distance / pace.milesPerHour) * 60.0
        
        guard steps > 0, timeMinutes > 0 else { return 0 }
        
        let spm = Double(steps) / timeMinutes
        return Int(ceil(spm))
    }
    
    func calculateCaloriesBurned(steps: Int, pace: Pace = .avgWalk) -> Int {
        // TODO: support custom duration
        let spm = stepsPerMinute(steps: steps, pace: pace)
        let weight = personalizationController.calculatedWeight
        let calculatedWeight = personalizationController.units == .metric ? weight : (weight * 0.453592)
        let durationInHours = Double(steps) / Double(spm) / 60.0
        
        guard durationInHours > 0 else { return 0 }
        
        return Int(ceil(pace.metValue * calculatedWeight * durationInHours))
    }
    
    func stepsPerUnit(pace: Pace = .avgWalk) -> Int {
        let unitInInches = personalizationController.units == .imperial ? 63360 : 39370.1
        return Int(ceil(unitInInches / strideLength()))
    }
    
    func secondsForDistance(distance: Double, pace: Pace = .avgWalk) -> Int {
        let speed: Double = personalizationController.units == .imperial ? pace.milesPerHour : (pace.milesPerHour * 1.60934)
        
        return Int(ceil((distance / speed) * 60 * 60))
    }
    
    func secondsFormatted(seconds: Int, full: Bool = false) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours) \(full ? "hour" : "hr")\(hours == 1 ? "" : "s") and \(minutes) \(full ? "minute" : "min")\(minutes == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) \(full ? "minute" : "min")\(minutes == 1 ? "" : "s")"
        } else {
            return "<1 \(full ? "minute" : "min")"
        }
    }
}
