//
//  DeviceNameTranslator.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/22/21.
//  
//
    

import Foundation
import CoreData

struct DeviceNameManager {
	private let viewContext = PersistenceController.shared.container.viewContext
	
	func getName(deviceUUID: String) -> String {
		let names = lookupNames()
		var deviceName: String = ""
		for i in names {
			if i.uuid == deviceUUID {
				deviceName = i.name ?? ""
			}
		}
		return deviceName
	}
	
	private func lookupNames() -> [DeviceNames] {
		var names: [DeviceNames] = []
		do {
			try names = viewContext.fetch(NSFetchRequest(entityName: "DeviceNames"))
		} catch {
			DebugLogManager.shared.debug(error: "Error accessing device names: \(error)", log: .app, date: Date())
		}
		return names
	}
	
	func clearName(deviceUUID: String) {
		let names = lookupNames()
		for i in names {
			if i.uuid == deviceUUID {
				viewContext.delete(i)
				do {
					try viewContext.save()
				} catch {
					DebugLogManager.shared.debug(error: "Error deleting device name for \(deviceUUID): \(error)", log: .app, date: Date())
				}
				DebugLogManager.shared.debug(error: "Deleted name for \(deviceUUID)", log: .app, date: Date())
			}
		}
	}
	
	func updateName(deviceUUID: String, name: String) {
		let names = lookupNames()
		if getName(deviceUUID: deviceUUID) == "" {
			setName(deviceUUID: deviceUUID, name: name)
		} else {
		writeName: for i in names {
			guard i.uuid == deviceUUID else { continue }
					i.name = name
					do {
						try viewContext.save()
					} catch {
						DebugLogManager.shared.debug(error: "Error saving device name for \(deviceUUID): \(error)", log: .app, date: Date())
					}
					DebugLogManager.shared.debug(error: "Updated name to \(name) for \(deviceUUID)", log: .app, date: Date())
					break writeName
			}
		}
		DeviceInfoManager().setDeviceName(uuid: deviceUUID)
	}
	
	func setName(deviceUUID: String, name: String) {
		let newName = DeviceNames(context: viewContext)
		newName.name = name
		newName.uuid = deviceUUID
	
		do {
			try viewContext.save()
		} catch {
			DebugLogManager.shared.debug(error: "Saved new name for \(deviceUUID): \(error)", log: .app, date: Date())
		}
	}
}

