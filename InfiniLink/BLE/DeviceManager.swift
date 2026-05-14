//
//  DeviceConnectionManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/16/24.
//

import SwiftUI
import CoreData
import CoreBluetooth

struct CharacteristicIdentifier {
    static let modelNumber = CBUUID(string: "2A24")
    static let serial = CBUUID(string: "2A25")
    static let firmware = CBUUID(string: "2A26")
    static let hardwareRevision = CBUUID(string: "2A27")
    static let softwareRevision = CBUUID(string: "2A28")
    static let manufacturer = CBUUID(string: "2A29")
    static let blefsVersion = CBUUID(string: "adaf0100-4669-6c65-5472-616e73666572")
}

class DeviceManager: ObservableObject {
    let persistenceController = PersistenceController.shared
    let bleManager = BLEManager.shared
    
    static let shared = DeviceManager()
    
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
        return bleManager.pairedDevice?.firmware ?? "1.0.0"
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
    
    var hour24: Bool {
        return settings.clockType == .H24
    }
    
    @Published var settings = Settings()
    @Published var watches = [Device]()
    
    init() {
        fetchAllDevices()
    }
    
    // Update persisted settings, before settings.dat has loaded
    func setSettings(_ device: Device? = nil) {
        let device = device ?? fetchDevice()!
        
        DispatchQueue.main.async {
            self.settings = Settings(
                version: UInt32(device.settingsVersion),
                stepsGoal: UInt32(device.stepsGoal),
                screenTimeOut: UInt32(device.screenTimeout),
                alwaysOnDisplay: device.alwaysOnDisplay,
                clockType: ClockType(rawValue: UInt8(device.clockType)) ?? .H24,
                weatherFormat: WeatherFormat(rawValue: UInt8(device.weatherFormat)) ?? .Metric,
                notificationStatus: Notification(rawValue: UInt8(device.notificationStatus)) ?? .On,
                watchFace: UInt8(device.watchface),
                chimesOption: ChimesOption(rawValue: UInt8(device.chimesOption)) ?? .None,
                pineTimeStyle: PineTimeStyleData(),
                watchFaceInfineat: WatchFaceInfineat(),
                wakeUpMode: .RaiseWrist,
                shakeWakeThreshold: UInt16(device.shakeWakeThreshold),
                brightLevel: BrightLevel(rawValue: UInt8(device.brightLevel)) ?? .Mid
            )
        }
    }
    
    func fetchDevice(with uuid: String? = nil) -> Device? {
        guard let id = uuid ?? bleManager.pairedDeviceID else { return nil }
        
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Device> = Device.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", id)
        
        do {
            let existingDevices = try context.fetch(fetchRequest)
            
            // There's already a paired watch
            if let existingDevice = existingDevices.first {
                setSettings(existingDevice)
                return existingDevice
            }
            
            // There's not already a paired watch, create a new object to save
            let newDevice = Device(context: context)
            context.perform {
                newDevice.uuid = id
                newDevice.blefsVersion = ""
                newDevice.firmware = ""
                newDevice.softwareRevision = ""
                newDevice.hardwareRevision = ""
                newDevice.manufacturer = ""
                newDevice.modelNumber = ""
                newDevice.serial = ""
                newDevice.stepsGoal = 10000
                
                do {
                    try context.save()
                } catch {
                    log("Error saving new device: \(error.localizedDescription)", caller: "DeviceManager - fetchDevice")
                }
            }
            
            setSettings(newDevice)
            
            return newDevice
        } catch {
            log("Error fetching or saving device: \(error)", caller: "DeviceManager")
            return nil
        }
    }
    
    // Get settings from settings file from watch and save it to keep device object up-to-date
    func updateSettings(settings: Settings) {
        guard let device = fetchDevice() else { return }
        let context = persistenceController.container.viewContext
        
        context.perform {
            device.brightLevel = Int16(settings.brightLevel.rawValue)
            device.chimesOption = Int16(settings.chimesOption.rawValue)
            device.clockType = Int16(settings.clockType.rawValue)
            device.notificationStatus = Int16(settings.notificationStatus.rawValue)
            device.shakeWakeThreshold = Int16(settings.watchFace)
            device.watchface = Int16(settings.watchFace)
            device.weatherFormat = Int16(settings.weatherFormat.rawValue)
            device.stepsGoal = Int32(settings.stepsGoal)
            device.screenTimeout = Int32(settings.screenTimeOut)
            
            device.pineTimeStyle?.colorBG = Int16(settings.pineTimeStyle.ColorBG.rawValue)
            device.pineTimeStyle?.colorBar = Int16(settings.pineTimeStyle.ColorBar.rawValue)
            device.pineTimeStyle?.colorTime = Int16(settings.pineTimeStyle.ColorTime.rawValue)
            device.pineTimeStyle?.guageStyle = Int16(settings.pineTimeStyle.gaugeStyle.rawValue)
            device.pineTimeStyle?.weatherEnable = Int16(settings.pineTimeStyle.weatherEnable.rawValue)
            
            device.watchFaceInfineat?.colorIndex = Int16(settings.watchFaceInfineat.colorIndex)
            device.watchFaceInfineat?.showSideCover = settings.watchFaceInfineat.showSideCover
            
            do {
                try context.save()
            } catch {
                log("Error saving settings: \(error.localizedDescription)", caller: "DeviceManager - updateSettings")
            }
        }
        
        // We've gotten the settings from the watch, now set our variables
        setSettings(device)
    }
    
    func updateName(name: String, for id: String) {
        guard let device = fetchDevice(with: id) else { return }
        
        device.name = name
        
        persistenceController.save()
    }
    
    func removeDevice(_ device: Device) {
        let objectID = device.objectID
        let context = persistenceController.container.viewContext
        
        context.perform { [self] in
            do {
                if let deviceToDelete = context.object(with: objectID) as? Device {
                    context.delete(deviceToDelete)
                    try context.save()
                    
                    fetchAllDevices()
                    if watches.count > 0 {
                        let nextWatch = watches.first!
                        bleManager.pairedDeviceID = nextWatch.uuid // Switch to the user's next watch
                        bleManager.pairedDevice = nextWatch
                    } else {
                        bleManager.pairedDeviceID = nil // The user doesn't have another watch, this will show the welcome view
                        // This only disconnects and removes the watch from the recognized device list in the app. If using secure pairing, iOS will still keep the bond
                        // and we have no way to remove it
                    }
                    bleManager.startScanning()
                    log("Successfully removed device", caller: "DeviceManager")
                }
            } catch {
                log("Error removing device: \(error.localizedDescription)", caller: "DeviceManager")
            }
        }
    }
    
    func fetchAllDevices() {
        DispatchQueue.main.async {
            do {
                self.watches = try self.persistenceController.container.viewContext.fetch(Device.fetchRequest())
            } catch {
                log("Error fetching devices: \(error.localizedDescription)", caller: "DeviceManager")
            }
        }
    }
}

extension DeviceManager {
    func updateInfo(characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }
        guard let objectID = bleManager.pairedDevice?.objectID else { return }

        let context = persistenceController.container.viewContext

        context.perform {
            do {
                guard let device = try context.existingObject(with: objectID) as? Device else { return }

                switch characteristic.uuid {
                case CharacteristicIdentifier.modelNumber:
                    device.modelNumber = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.serial:
                    device.serial = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.firmware:
                    device.firmware = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.hardwareRevision:
                    device.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.softwareRevision:
                    device.softwareRevision = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.manufacturer:
                    device.manufacturer = String(data: value, encoding: .utf8) ?? ""
                case CharacteristicIdentifier.blefsVersion:
                    let byteArray = [UInt8](value)
                    if byteArray.count >= 2 {
                        device.blefsVersion = "\(Int(byteArray[1]))\(Int(byteArray[0]))"
                    } else {
                        device.blefsVersion = "00"
                    }
                default:
                    break
                }

                try context.save()
            } catch {
                log("Failed to update paired device: \(error)", caller: "DeviceManager", target: .ble)
            }
        }
    }
    
    func readInfoCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case CharacteristicIdentifier.modelNumber, CharacteristicIdentifier.serial, CharacteristicIdentifier.firmware, CharacteristicIdentifier.hardwareRevision, CharacteristicIdentifier.softwareRevision, CharacteristicIdentifier.manufacturer, CharacteristicIdentifier.blefsVersion: peripheral.readValue(for: characteristic)
        default:
            break
        }
    }
}
