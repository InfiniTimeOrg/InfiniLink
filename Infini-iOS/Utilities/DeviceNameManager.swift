//
//  DeviceNameTranslator.swift
//  Infini-iOS
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
			print(error.localizedDescription)
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
					print(error.localizedDescription)
				}
				print("Deleted name for \(deviceUUID)!")
			}
		}
	}
	
	func updateName(deviceUUID: String, name: String) -> String {
		var message = ""
		let names = lookupNames()
		if getName(deviceUUID: deviceUUID) == "" {
			setName(deviceUUID: deviceUUID, name: name)
			message = "Wrote new name for \(deviceUUID)!"
			print(message)
		} else {
		writeName: for i in names {
			guard i.uuid == deviceUUID else { continue }
				//if i.uuid == deviceUUID {
					i.name = name
					do {
						try viewContext.save()
					} catch {
						print(error.localizedDescription)
					}
					message = "Updated name for \(deviceUUID)!"
					print(message)
					break writeName
				//}
			}
		}
		DeviceInfoManager().setDeviceName(uuid: deviceUUID)
		return message
	}
	
	func setName(deviceUUID: String, name: String) {
		let newName = DeviceNames(context: viewContext)
		newName.name = name
		newName.uuid = deviceUUID
	
		do {
			try viewContext.save()
		} catch {
			print(error.localizedDescription)
		}
	}
}

