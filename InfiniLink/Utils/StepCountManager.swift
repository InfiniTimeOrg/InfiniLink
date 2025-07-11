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
    
    // The following two functions need to use the viewContext to save because the objects they're updating were fetched on that context
    func setStepCount(steps: Int32, isArbitrary: Bool, for date: Date) {
        let existing = chartManager.stepsToday()
        
        if let existing {
            updateStepCount(existing, with: steps, for: date, isArbitrary: isArbitrary)
        } else {
            chartManager.addStepDataPoint(steps: steps, time: date)
        }
    }
    
    private func updateStepCount(_ current: StepCounts, with steps: Int32, for date: Date, isArbitrary: Bool) {
        if isArbitrary {
            current.steps += steps
        }
//        else if addInsteadOfOverwrite && steps <= current.steps {
//            if steps <= current.previousSteps {
//                current.steps += steps
//            } else {
//                current.steps += abs(current.previousSteps - steps)
//            }
//        }
        else {
            current.steps = steps
        }
        
        current.timestamp = date
        current.previousSteps = steps
        
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
