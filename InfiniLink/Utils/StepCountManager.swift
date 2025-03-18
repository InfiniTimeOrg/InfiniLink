//
//  StepCountManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import CoreData

class StepCountManager: ObservableObject {
    static let shared = StepCountManager()
    
    let chartManager = ChartManager.shared
    let bleManager = BLEManager.shared
    let persistenceManager = PersistenceController.shared
    
    var stepGoal: Int {
        return Int(DeviceManager.shared.settings.stepsGoal)
    }
    var hasReachedStepGoal: Bool {
        return BLEManager.shared.stepCount >= stepGoal
    }
    
    // The following two functions need to use the viewContext to save because the objects they're updating were fetched on that context
    func setStepCount(steps: Int32, isArbitrary: Bool, for date: Date) {
        let existing = chartManager.stepsToday()
        
        if let existing {
            updateStepCount(existing, with: steps, isArbitrary: isArbitrary, for: date)
        } else {
            chartManager.addStepDataPoint(steps: steps, time: date)
        }
    }
    
    private func updateStepCount(_ stepCount: StepCounts, with steps: Int32, isArbitrary: Bool, for date: Date) {
        if isArbitrary {
            stepCount.steps += steps
        } else {
            clearCurrentDaySteps()
            stepCount.steps = max(stepCount.steps, steps)
        }
        
        stepCount.timestamp = date
        
        persistenceManager.save()
    }
    
    func clearCurrentDaySteps() {
        let now = Date()
        let existing = chartManager.stepsToday()
        
        if let existing {
            existing.steps = 0
            existing.timestamp = now
        } else {
            chartManager.addStepDataPoint(steps: 0, time: now)
        }
        
        persistenceManager.save()
    }
}
