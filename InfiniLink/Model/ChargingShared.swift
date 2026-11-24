//
//  ChargingShared.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import Foundation
import ActivityKit

struct ChargingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var level: Int
        var isFull: Bool
        var fullAt: Date?
        var uptime: TimeInterval?
    }

    var deviceName: String
}
