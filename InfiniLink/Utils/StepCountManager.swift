//
//  StepCountManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import CoreData
import SwiftUI

class StepCountManager: ObservableObject {
    static let shared = StepCountManager()
    
    let chartManager = ChartManager.shared
    let persistenceManager = PersistenceController.shared
    let deviceManager = DeviceManager.shared
    
    var stepGoal: Int {
        return Int(deviceManager.settings.stepsGoal)
    }
    
    func setStepCount(_ steps: Int, for date: Date = Date()) {
        let existing = chartManager.stepsToday()
        let steps = Int32(steps)
        
        if let existing {
            updateStepCount(existing, with: steps, for: date)
        } else {
            chartManager.addStepDataPoint(steps: steps, time: date)
        }
    }
    
    private func updateStepCount(_ existing: StepCounts, with steps: Int32, for date: Date = Date()) {
        existing.timestamp = date
        existing.previousSteps = existing.steps
        existing.steps = steps
        
        persistenceManager.save()
    }
    
    func clearCurrentDaySteps() {
        if let existing = chartManager.stepsToday() {
            existing.steps = 0
            existing.timestamp = Date()
        }
        
        persistenceManager.save()
    }
}
