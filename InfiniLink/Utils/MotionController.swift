//
//  MotionController.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import Foundation

class MotionController {
    static let shared = MotionController()

    private let epochDuration: TimeInterval = 60

    private var epochStart: Date?
    private var previousMagnitude: Double?
    private var accumulatedActivity: Double = 0

    // x/y/z are raw accelerometer readings from InfiniTime's motion characteristic (~1024 units/g)
    func ingest(x: Int16, y: Int16, z: Int16, at time: Date = Date()) {
        let magnitude = sqrt(Double(x) * Double(x) + Double(y) * Double(y) + Double(z) * Double(z))

        if let previousMagnitude {
            accumulatedActivity += abs(magnitude - previousMagnitude)
        }
        previousMagnitude = magnitude

        guard let epochStart else {
            self.epochStart = time
            return
        }

        if time.timeIntervalSince(epochStart) >= epochDuration {
            ChartManager.shared.addMotionActivityPoint(activity: accumulatedActivity, time: epochStart)
            self.epochStart = time
            accumulatedActivity = 0
        }
    }
}
