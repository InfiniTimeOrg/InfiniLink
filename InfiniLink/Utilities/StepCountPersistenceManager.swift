//
//  StepCountPersistenceManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/27/21.
//  
//
    

import CoreData

struct StepCountPersistenceManager {
	let viewContext = PersistenceController.shared.container.viewContext
	
	func lookupStepCounts(write: Bool) -> [StepCounts] {
		var existingCounts: [StepCounts] = []
		let request = NSFetchRequest<StepCounts>(entityName: "StepCounts")
		if write {
			request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
			request.fetchLimit = 1
		}
		do {
			try existingCounts = viewContext.fetch(request)
		} catch {
			DebugLogManager.shared.debug(error: "Error accessing step counts: \(error)", log: .app, date: Date())
		}
		return existingCounts
	}
	
	func setStepCount(steps: Int) {
		let existingCounts = lookupStepCounts(write: true)
		
		for i in existingCounts {
			if Calendar.current.isDateInToday(i.timestamp!) {
				if steps > i.steps {
					i.timestamp = Date()
					i.steps = Int32(steps)
					do {
						try viewContext.save()
					} catch {
						DebugLogManager.shared.debug(error: "Couldn't save step count: \(error)", log: .app, date: Date())
					}
					return
				}
			}
		}
		
		let newCount = StepCounts(context: viewContext)
		newCount.steps = Int32(steps)
		newCount.timestamp = Date()

		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Couldn't save step count: \(error)", log: .app, date: Date())
		}
	}
}
