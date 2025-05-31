//
//  RSSI.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/31/25.
//
//

import SwiftUI

enum RSSI {
    case excellent
    case good
    case fair
    case poor
    
    var connectionStrength: LocalizedStringKey {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent, .good:
            return .green
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
    
    func estimateDistance(from rssi: Int, measuredPower: Int = -59, pathLossExponent n: Double = 2.2) -> Double {
        let ratio = Double(measuredPower - rssi) / (10 * n)
        let meterDistance = pow(10.0, ratio)
        let meterMultiplier = 3.281
        
        return max(meterDistance  / (PersonalizationController.shared.units == .metric ? 1 : meterMultiplier), 0)
    }

    static func from(rssi: Int) -> RSSI {
        switch rssi {
        case let x where x >= -60:
            return .excellent
        case -75 ... -61:
            return .good
        case -90 ... -76:
            return .fair
        default:
            return .poor // Over 90
        }
    }
}
