//
//  StepCountManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/7/24.
//

import CoreData

class StepCountManager: ObservableObject {
    static let shared = StepCountManager()
    
    let viewContext = PersistenceController.shared.container.viewContext
    
    func fetchStepCounts() -> [StepCounts] {
        let request: NSFetchRequest<StepCounts> = StepCounts.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            log(error.localizedDescription, caller: "StepCountManager")
            return []
        }
    }
    
    func setStepCount(steps: Int32, isArbitrary: Bool, for date: Date) {
        let existingCounts = fetchStepCounts()
        
        if let existingCount = existingCounts.first(where: { Calendar.current.isDate($0.timestamp!, inSameDayAs: date) }) {
            updateStepCount(existingCount, with: steps, isArbitrary: isArbitrary, for: date)
        } else {
            saveNewStepCount(steps: steps, date: date)
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
        saveContext()
    }
    
    func clearCurrentDaySteps() {
        let today = Date()
        let existingCounts = fetchStepCounts()
        
        if let currentDayCount = existingCounts.first(where: { Calendar.current.isDate($0.timestamp!, inSameDayAs: today) }) {
            currentDayCount.steps = 0
            currentDayCount.timestamp = today
        } else {
            saveNewStepCount(steps: 0, date: today)
        }
        
        saveContext()
    }
    
    private func saveNewStepCount(steps: Int32, date: Date) {
        let newCount = StepCounts(context: viewContext)
        newCount.steps = steps
        newCount.timestamp = date
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            log(error.localizedDescription, caller: "StepCountManager")
        }
    }
}
