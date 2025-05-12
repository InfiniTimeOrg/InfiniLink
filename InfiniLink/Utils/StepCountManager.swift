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
    let bleManager = BLEManager.shared
    let persistenceManager = PersistenceController.shared
    
    @AppStorage("addInsteadOfOverwrite") var addInsteadOfOverwrite: Bool = false
    
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
    
    private func updateStepCount(_ current: StepCounts, with steps: Int32, isArbitrary: Bool, for date: Date) {
        // Last saved step count is current.steps = 978
        // We just received steps = 0
        if addInsteadOfOverwrite {
            // We have to do some math here because otherwise we'll just double the value
            if steps <= current.steps { // The watch reset, so add the new steps to the old count
                // This is fairly accurate, although about 6 steps get added because the watch tracks around that many before it sends the count (before we can set current.previousSteps)
                current.steps += abs(current.previousSteps - steps)
            } else {
                current.steps += abs(current.steps - steps)
            }
        } else if isArbitrary {
            current.steps += steps
        } else {
            clearCurrentDaySteps()
            current.steps = steps
        }
        
        current.timestamp = date
        current.previousSteps = steps
        
        persistenceManager.save()
    }
    
    func clearCurrentDaySteps() {
        if let existing = chartManager.stepsToday(){
            existing.steps = 0
            existing.timestamp = Date()
        }
        
        persistenceManager.save()
    }
}
