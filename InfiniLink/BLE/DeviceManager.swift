//
//  DeviceConnectionManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/16/24.
//

import SwiftUI
import CoreData
import CoreBluetooth

class DeviceManager: ObservableObject {
    struct cbuuid {
        let modelNumber = CBUUID(string: "2A24")
        let serial = CBUUID(string: "2A25")
        let firmware = CBUUID(string: "2A26")
        let hardwareRevision = CBUUID(string: "2A27")
        let softwareRevision = CBUUID(string: "2A28")
        let manufacturer = CBUUID(string: "2A29")
        let blefsVersion = CBUUID(string: "adaf0100-4669-6c65-5472-616e73666572")
    }
    let cbuuids = cbuuid()
    
    let context = PersistenceController.shared.container.viewContext
    let bleManager = BLEManager.shared
    
    static let shared = DeviceManager()
    
    // TODO: persist settings
    @Published var settings = Settings()
    
    var name: String {
        return bleManager.pairedDevice?.name ?? "InfiniTime"
    }
    var modelNumber: String {
        return bleManager.pairedDevice?.modelNumber ?? ""
    }
    var serial: String {
        return bleManager.pairedDevice?.serial ?? ""
    }
    var firmware: String {
        return bleManager.pairedDevice?.firmware ?? ""
    }
    var hardwareRevision: String {
        return bleManager.pairedDevice?.hardwareRevision ?? ""
    }
    var softwareRevision: String {
        return bleManager.pairedDevice?.softwareRevision ?? ""
    }
    var manufacturer: String {
        return bleManager.pairedDevice?.manufacturer ?? ""
    }
    var blefsVersion: String {
        return bleManager.pairedDevice?.blefsVersion ?? ""
    }
    var bleUUID: String {
        return bleManager.pairedDevice?.bleUUID ?? ""
    }
    
    var hour24: Bool {
        return settings.clockType == .H24
    }
    
    func fetchDevice(with uuid: String? = nil) -> Device {
        let id: String = uuid ?? (bleManager.pairedDeviceID ?? "")
        
        let fetchRequest: NSFetchRequest<Device> = Device.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", id)
        
        do {
            let existingDevices = try context.fetch(fetchRequest)
            
            if let existingDevice = existingDevices.first {
                return existingDevice
            } else {
                let newDevice = Device(context: context)
                newDevice.uuid = uuid
                newDevice.bleUUID = uuid
                newDevice.blefsVersion = ""
                newDevice.firmware = ""
                newDevice.hardwareRevision = ""
                newDevice.manufacturer = ""
                newDevice.modelNumber = ""
                newDevice.serial = ""
                newDevice.uuid = uuid
                
                try context.save()
                return newDevice
            }
        } catch {
            fatalError("Error fetching or saving device: \(error)")
        }
    }
    
    func updateName(name: String, for device: Device) {
        guard let uuid = device.uuid else { return }
        
        let device = fetchDevice(with: uuid)
        device.name = name
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchAllDevices() -> [Device]? {
        let fetchRequest: NSFetchRequest<Device> = Device.fetchRequest()
        
        do {
            let devices = try context.fetch(fetchRequest)
            return devices
        } catch {
            print("Error fetching devices: \(error)")
            return nil
        }
    }
}

extension DeviceManager {
    func updateInfo(characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }
        
        bleManager.pairedDevice.bleUUID = characteristic.uuid.uuidString
        
        switch characteristic.uuid {
        case cbuuids.modelNumber:
            bleManager.pairedDevice.modelNumber = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.serial:
            bleManager.pairedDevice.serial = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.firmware:
            bleManager.pairedDevice.firmware = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.hardwareRevision:
            bleManager.pairedDevice.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.softwareRevision:
            bleManager.pairedDevice.softwareRevision = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.manufacturer:
            bleManager.pairedDevice.manufacturer = String(data: value, encoding: .utf8) ?? ""
        case cbuuids.blefsVersion:
            let byteArray = [UInt8](characteristic.value!)
            bleManager.pairedDevice.blefsVersion = String(Int(byteArray[1])) + String(Int(byteArray[0]))
        default:
            break
        }
    }
    
    func readInfoCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case cbuuids.modelNumber, cbuuids.serial, cbuuids.firmware, cbuuids.hardwareRevision, cbuuids.softwareRevision, cbuuids.manufacturer, cbuuids.blefsVersion: peripheral.readValue(for: characteristic)
        default:
            break
        }
    }
}
