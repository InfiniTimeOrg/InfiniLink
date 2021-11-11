//
//  StepCountPersistenceManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/27/21.
//  
//
    

import CoreData
import SwiftUI

class StepCountPersistenceManager: ObservableObject {
	static let shared = StepCountPersistenceManager()
	@Published var currentCount: Int32 = 0
	let viewContext = PersistenceController.shared.container.viewContext
	
	init() {
		retrieveStepCount(date: Date())
	}
	
	func lookupStepCounts(write: Bool) -> [StepCounts] {
		var existingCounts: [StepCounts] = []
		let request = NSFetchRequest<StepCounts>(entityName: "StepCounts")
		do {
			try existingCounts = viewContext.fetch(request)
		} catch {
			DebugLogManager.shared.debug(error: "Error accessing step counts: \(error)", log: .app, date: Date())
		}
		return existingCounts
	}
	
	func retrieveStepCount(date: Date) {
		let existingCounts = lookupStepCounts(write: true)
		for i in existingCounts {
			if Calendar.current.isDate(i.timestamp!, inSameDayAs: date) {
				currentCount = i.steps
			}
		}
	}
	
	func setStepCount(steps: Int, arbitrary: Bool, date: Date) {
		let existingCounts = lookupStepCounts(write: true)
		
		let countExists = existingCounts.contains { count in
			if Calendar.current.isDate(date, inSameDayAs: count.timestamp!) {
				return true
			} else {
				return false
			}
		}
		
		if countExists {
			for i in existingCounts {
				if Calendar.current.isDate(i.timestamp!, inSameDayAs: date) {
					if arbitrary {
						overwriteStepCount(oldStepCount: i, newSteps: steps, date)
					} else {
						if steps > i.steps {
							overwriteStepCount(oldStepCount: i, newSteps: steps, date)
							return
						}
					}
				}
			}
		} else {
			saveNewStepCount(steps: steps, date: date)
		}
	}
	
	func overwriteStepCount(oldStepCount: StepCounts, newSteps: Int, _ newDate: Date) {
		oldStepCount.timestamp = newDate
		oldStepCount.steps = Int32(newSteps)
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Couldn't save step count: \(error)", log: .app, date: Date())
		}
		retrieveStepCount(date: Date())
	}
	
	func saveNewStepCount(steps: Int, date: Date) {
		let newCount = StepCounts(context: viewContext)
		newCount.steps = Int32(steps)
		newCount.timestamp = date
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Couldn't save step count: \(error)", log: .app, date: Date())
		}
		retrieveStepCount(date: Date())
	}
}
