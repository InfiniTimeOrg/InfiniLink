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
    
    var icon: String {
        switch self {
        case .steps:
            return "shoeprints.fill"
        case .heart:
            return "heart.fill"
        case .battery:
            return "battery.50percent.fill"
        case .sleep:
            return "moon.fill"
        }
    }
}
