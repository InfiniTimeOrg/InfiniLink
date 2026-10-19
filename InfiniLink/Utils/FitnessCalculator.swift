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
    
    var kmPerHour: Double {
        switch self {
        case .verySlowWalk: return 1.6
        case .slowWalk: return 3.0
        case .avgWalk: return 5.0
        case .briskWalk: return 6.5
        case .jog: return 8.0
        case .run: return 9.5
        case .fastRun: return 12.0
        case .veryFastRun: return 16.0
        }
    }
}

class FitnessCalculator {
    let personalizationController = PersonalizationController.shared
    
    // In meters
    func strideLength(pace: Pace = .avgWalk) -> Double {
        let avgStrideRatio = personalizationController.gender == .male ? 0.415 : 0.413
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
        
        return personalizationController.calculatedHeightCm / 100 * avgStrideRatio * strideMultiplier
    }
    
    // In miles or kilometers, depending on the user's units
    func calculateDistance(steps: Int, pace: Pace = .avgWalk) -> Double {
        let meters = strideLength(pace: pace) * Double(steps)
        return personalizationController.units == .imperial ? meters / 1609.344 : meters / 1000
    }
    
    func stepsPerMinute(pace: Pace = .avgWalk) -> Int {
        Int(ceil(pace.kmPerHour * 1000 / 60 / strideLength(pace: pace)))
    }
    
    func calculateCaloriesBurned(steps: Int, pace: Pace = .avgWalk) -> Int {
        let hours = strideLength(pace: pace) * Double(steps) / 1000 / pace.kmPerHour
        
        // Subtract 1 MET (resting) so this is active energy, matching HealthKit's activeEnergyBurned
        return Int(ceil((pace.metValue - 1.0) * personalizationController.calculatedWeightKg * hours))
    }

    // Heart-rate based active energy estimate (Keytel et al. 2005)
    func calculateCaloriesBurned(heartRate: Double, durationSeconds: TimeInterval) -> Int {
        guard heartRate > 0, durationSeconds > 0 else { return 0 }

        let minutes = durationSeconds / 60.0
        let weight = personalizationController.calculatedWeightKg
        let age = personalizationController.calculatedAge

        let grossKcalPerMinute: Double = {
            if personalizationController.gender == .male {
                return (-55.0969 + (0.6309 * heartRate) + (0.1988 * weight) + (0.2017 * age)) / 4.184
            } else {
                return (-20.4022 + (0.4472 * heartRate) - (0.1263 * weight) + (0.0740 * age)) / 4.184
            }
        }()

        // Keytel predicts gross expenditure so subtract 1 MET (resting) because we want active energy
        let restingKcalPerMinute = weight / 60.0

        return Int(max(0, (grossKcalPerMinute - restingKcalPerMinute) * minutes).rounded())
    }
    
    // Distance is in miles or kilometers, depending on the user's units
    func secondsForDistance(distance: Double, pace: Pace = .avgWalk) -> Int {
        let km = personalizationController.units == .imperial ? distance * 1.609344 : distance
        return Int(ceil(km / pace.kmPerHour * 3600))
    }
    
    func distanceString(meters: Double) -> String {
        if personalizationController.units == .imperial {
            return String(format: "%.2f mi", meters / 1609.344)
        } else {
            return String(format: "%.2f km", meters / 1000)
        }
    }

    func energyValue(kcal: Double) -> Int {
        switch personalizationController.energyUnit {
        case .kilojoule: return Int((kcal * 4.184).rounded())
        case .kilocalorie: return Int(kcal.rounded())
        }
    }

    func energyUnitLabel(short: Bool = false) -> String {
        switch personalizationController.energyUnit {
        case .kilojoule: return "kJ"
        case .kilocalorie: return short ? "cal" : "kcal"
        }
    }

    // e.g. 190 kcal or 795 kJ
    func energyString(kcal: Double) -> String {
        return "\(energyValue(kcal: kcal)) \(energyUnitLabel())"
    }

    func secondsFormatted(seconds: Int, full: Bool = false) -> String {
        let hours = Double(seconds) / 3600.0
        let minutes = (seconds % 3600) / 60
        
        if hours >= 1 {
            return "\(String(format: "%.2f", hours)) \(full ? "hour" : "hr")\(hours == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) \(full ? "minute" : "min")\(minutes == 1 ? "" : "s")"
        } else {
            return "<1 \(full ? "minute" : "min")"
        }
    }
}
