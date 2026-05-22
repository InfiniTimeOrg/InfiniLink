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
    static let shared = DeviceManager()
    
    let persistenceController = PersistenceController.shared
    let bleManager = BLEManager.shared
    
    @Published var pairedDevice: Device?
    
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    
    var name: String {
        return pairedDevice?.name ?? "InfiniTime"
    }
    var modelNumber: String {
        return pairedDevice?.modelNumber ?? ""
    }
    var serial: String {
        return pairedDevice?.serial ?? ""
    }
    var firmware: String {
        return pairedDevice?.firmware ?? "1.0.0"
    }
    var hardwareRevision: String {
        return pairedDevice?.hardwareRevision ?? ""
    }
    var softwareRevision: String {
        return pairedDevice?.softwareRevision ?? ""
    }
    var manufacturer: String {
        return pairedDevice?.manufacturer ?? ""
    }
    var blefsVersion: String {
        return pairedDevice?.blefsVersion ?? ""
    }
    
    var hour24: Bool {
        return settings.clockType == .H24
    }
    
    @Published var settings = Settings()
    @Published var watches = [Device]()
    
    init() {
        self.fetchAllDevices()
        self.pairedDevice = currentDevice()

        if let settings = pairedDevice?.settings() {
            self.settings = settings
        }
    }
    
    func updateSettings(_ settings: Settings) {
        let context = persistenceController.container.viewContext

        context.perform {
            guard let device = self.currentDevice(in: context) else { return }

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

            try? context.save()
            
            self.settings = settings
        }
    }
    
    func updateName(_ name: String) {
        guard let device = currentDevice() else { return }
        
        device.name = name
        
        persistenceController.save()
    }
    
    func device(for uuid: String, in context: NSManagedObjectContext) -> Device {
        let request: NSFetchRequest<Device> = Device.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let newDevice = Device(context: context)
        newDevice.uuid = uuid
        return newDevice
    }
    
    func currentDevice(in context: NSManagedObjectContext? = nil) -> Device? {
        guard let id = pairedDeviceID else { return nil }
        return device(for: id, in: context ?? persistenceController.container.viewContext)
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
                        pairedDeviceID = nextWatch.uuid // Switch to the user's next watch
                        pairedDevice = nextWatch
                    } else {
                        pairedDeviceID = nil // The user doesn't have another watch, this will show the welcome view
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
        let context = persistenceController.container.viewContext

        context.perform {
            let request: NSFetchRequest<Device> = Device.fetchRequest()
            request.returnsObjectsAsFaults = false

            do {
                let results = try context.fetch(request)
                DispatchQueue.main.async {
                    self.watches = results
                }
            } catch {
                print(error)
            }
        }
    }
    
    func deleteAllDevices() {
        let context = persistenceController.container.viewContext

        context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = Device.fetchRequest()
            let delete = NSBatchDeleteRequest(fetchRequest: request)
            delete.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(delete) as? NSBatchDeleteResult
                let ids = result?.result as? [NSManagedObjectID] ?? []

                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                    into: [context]
                )

                try context.save()
            } catch {
                print(error)
            }
        }
    }
}

extension DeviceManager {
    func updateInfo(characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }

        let context = persistenceController.container.viewContext

        context.perform {
            guard let device = self.currentDevice(in: context) else { return }

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

            try? context.save()
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

extension Device {
    func settings() -> Settings {
        return Settings(
            version: UInt32(self.settingsVersion),
            stepsGoal: UInt32(self.stepsGoal),
            screenTimeOut: UInt32(self.screenTimeout),
            alwaysOnDisplay: self.alwaysOnDisplay,
            clockType: ClockType(rawValue: UInt8(self.clockType)) ?? .H24,
            weatherFormat: WeatherFormat(rawValue: UInt8(self.weatherFormat)) ?? .Metric,
            notificationStatus: Notification(rawValue: UInt8(self.notificationStatus)) ?? .On,
            watchFace: UInt8(self.watchface),
            chimesOption: ChimesOption(rawValue: UInt8(self.chimesOption)) ?? .None,
            pineTimeStyle: PineTimeStyleData(),
            watchFaceInfineat: WatchFaceInfineat(),
            wakeUpMode: .RaiseWrist,
            shakeWakeThreshold: UInt16(self.shakeWakeThreshold),
            brightLevel: BrightLevel(rawValue: UInt8(self.brightLevel)) ?? .Mid
        )
    }
}
