//
//  ChartType.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/10/25.
//

import Foundation

enum ChartType: String {
    case steps
    case heart
    case battery
    case sleep
    
    var name: String {
        switch self {
        case .steps:
            return NSLocalizedString("steps", comment: "")
        case .heart:
            return NSLocalizedString("heart", comment: "")
        case .battery:
            return NSLocalizedString("battery", comment: "")
        case .sleep:
            return NSLocalizedString("sleep", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .steps:
            return "shoeprints.fill"
        case .heart:
            return "heart.fill"
        case .battery:
            return "battery.25.fill"
        case .sleep:
            return "bed.double.fill"
        }
    }
}
