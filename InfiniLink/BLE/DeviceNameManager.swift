//
//  DeviceNameTranslator.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/22/21.
//  
//

import Foundation
import CoreData

struct DeviceName {
    var name: String
    let uuid: String
}

struct DeviceNameManager {
	func getName(deviceUUID: String) -> String {
		let names = lookupNames()
		var deviceName: String = ""
        
		for i in names {
			if i.uuid == deviceUUID {
				deviceName = i.name
			}
		}
        
		return deviceName
	}
	
	private func lookupNames() -> [DeviceName] {
		var names: [DeviceName] = []
        
        names = (UserDefaults.standard.array(forKey: "deviceNames") as? [DeviceName]) ?? []
        
		return names
	}
	
	func clearName(deviceUUID: String) {
		var names = lookupNames()
        
		for i in names {
			if i.uuid == deviceUUID {
                guard let index = names.firstIndex(where: { $0.uuid == deviceUUID }) else { return }
                
                names.remove(at: index)
                UserDefaults.standard.set(names, forKey: "deviceNames")
			}
		}
	}
	
	func updateName(deviceUUID: String, name: String) {
        let names = lookupNames()
        
		if getName(deviceUUID: deviceUUID) == "" {
			setName(deviceUUID: deviceUUID, name: name)
        } else {
            for i in names {
                guard i.uuid == deviceUUID else { continue }
                
                clearName(deviceUUID: deviceUUID)
                setName(deviceUUID: deviceUUID, name: name)
            }
        }
        DeviceInfoManager.shared.setDeviceName(uuid: deviceUUID)
	}
	
	func setName(deviceUUID: String, name: String) {
        let newName = DeviceName(name: name, uuid: deviceUUID)
        
		var names = lookupNames()
        names.append(newName)
        
        UserDefaults.standard.set(names, forKey: "deviceNames")
	}
}

