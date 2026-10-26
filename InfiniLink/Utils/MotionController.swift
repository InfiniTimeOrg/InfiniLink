//
//  MotionController.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import Foundation

class MotionController: ObservableObject {
    static let shared = MotionController()

    @Published var isAccelerometerDead = UserDefaults.standard.bool(forKey: "isAccelerometerDead") {
        didSet { UserDefaults.standard.set(isAccelerometerDead, forKey: "isAccelerometerDead") }
    }
    @Published var fakeDeadAccelerometer = false

    private let epochDuration: TimeInterval = 60

    private var lastReading: Date?

    private var epochStart: Date?
    private var previousMagnitude: Double?
    private var accumulatedActivity: Double = 0

    // x/y/z are raw accelerometer readings the motion characteristic (~1024 units/g)
    func ingest(x: Int16, y: Int16, z: Int16, at time: Date = Date()) {
        guard x != 0 || y != 0 || z != 0 else { return } // We'll never get zero values unless the accel is dead
        lastReading = time
        if isAccelerometerDead { isAccelerometerDead = false }

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

    func checkAccelerometer() { // Detect a dead accel
        let start = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            guard BLEManager.shared.isConnectedToPinetime else { return }
            if (self.lastReading ?? .distantPast) < start {
                self.isAccelerometerDead = true
            }
        }
    }
}
