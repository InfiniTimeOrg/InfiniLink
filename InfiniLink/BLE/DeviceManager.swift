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
    static let shared = DeviceManager()
    
    let persistenceController = PersistenceController.shared
    
    @Published var pairedDevice: Device? {
        didSet {
            settings = pairedDevice.map { Settings(device: $0) } ?? Settings()
        }
    }
    
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
    
    var heartRateBackgroundPeriod: Int? {
        get { UserDefaults.standard.object(forKey: "heartRateBackgroundPeriod-\(pairedDeviceID ?? "")") as? Int }
        set {
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "heartRateBackgroundPeriod-\(pairedDeviceID ?? "")")
        }
    }
    
    func updateHeartRateBackgroundPeriod(from file: WatchSettingsFile) {
        guard file.supportsBackgroundHeartRate else { return }
        
        DispatchQueue.main.async {
            self.heartRateBackgroundPeriod = file.heartRateBackgroundPeriod.map { Int($0) } ?? -1
        }
    }
    
    @Published var watches = [Device]()
    
    init() {
        fetchAllDevices()
        pairedDevice = currentDevice()
        // didSet doesn't run during init
        settings = pairedDevice.map { Settings(device: $0) } ?? Settings()
    }
    
    func updateSettings(_ settings: Settings) {
        let context = persistenceController.container.viewContext

        context.perform {
            guard let device = self.currentDevice(in: context) else { return }

            device.brightLevel = Int16(settings.brightLevel.rawValue)
            device.chimesOption = Int16(settings.chimesOption.rawValue)
            device.clockType = Int16(settings.clockType.rawValue)
            device.notificationStatus = Int16(settings.notificationStatus.rawValue)
            device.shakeWakeThreshold = Int16(clamping: settings.shakeWakeThreshold)
            device.watchface = Int16(settings.watchFace)
            device.weatherFormat = Int16(settings.weatherFormat.rawValue)
            device.stepsGoal = Int32(settings.stepsGoal)
            device.screenTimeout = Int32(settings.screenTimeOut)
            device.alwaysOnDisplay = settings.alwaysOnDisplay
            device.prideFlag = Int16(settings.prideFlag)
            
            let pineTimeStyle = device.pineTimeStyle ?? PineTimeStyleWatchface(context: context)
            pineTimeStyle.colorBG = Int16(settings.pineTimeStyle.ColorBG.rawValue)
            pineTimeStyle.colorBar = Int16(settings.pineTimeStyle.ColorBar.rawValue)
            pineTimeStyle.colorTime = Int16(settings.pineTimeStyle.ColorTime.rawValue)
            pineTimeStyle.guageStyle = Int16(settings.pineTimeStyle.gaugeStyle.rawValue)
            pineTimeStyle.weatherEnable = Int16(settings.pineTimeStyle.weatherEnable.rawValue)
            device.pineTimeStyle = pineTimeStyle
            
            let infineat = device.watchFaceInfineat ?? InfineatWatchface(context: context)
            infineat.colorIndex = Int16(settings.watchFaceInfineat.colorIndex)
            infineat.showSideCover = settings.watchFaceInfineat.showSideCover
            device.watchFaceInfineat = infineat

            try? context.save()
            
            self.settings = settings
        }
    }
    
    func updateName(_ name: String) {
        guard let device = currentDevice() else { return }
        
        device.name = name
        
        persistenceController.save()
    }
    
    func currentDevice(in context: NSManagedObjectContext? = nil) -> Device? {
        guard let id = pairedDeviceID else { return nil }
        
        let request: NSFetchRequest<Device> = Device.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", id)
        request.fetchLimit = 1
        
        return try? (context ?? persistenceController.container.viewContext).fetch(request).first
    }
    
    func addDevice(uuid: String) -> Device {
        let device = Device(context: persistenceController.container.viewContext)
        device.uuid = uuid
        
        persistenceController.save()
        fetchAllDevices()
        return device
    }
    
    func removeDevice(_ device: Device) {
        let context = persistenceController.container.viewContext
        context.delete(device)
        
        do {
            try context.save()
        } catch {
            log("Error removing device: \(error.localizedDescription)", caller: "DeviceManager")
            return
        }
        
        fetchAllDevices()
        // Switch to the user's next watch, or show the welcome view if there isn't one. If using secure pairing, iOS will still keep the bond and we have no way to remove it
        pairedDeviceID = watches.first?.uuid
        pairedDevice = watches.first
        
        log("Successfully removed device", type: .info, caller: "DeviceManager")
    }
    
    func fetchAllDevices() {
        do {
            watches = try persistenceController.container.viewContext.fetch(Device.fetchRequest())
        } catch {
            log("Error fetching devices: \(error.localizedDescription)", caller: "DeviceManager")
        }
    }
    
    func deleteAllDevices() {
        let context = persistenceController.container.viewContext
        let delete = NSBatchDeleteRequest(fetchRequest: Device.fetchRequest())
        delete.resultType = .resultTypeObjectIDs
        
        do {
            let result = try context.execute(delete) as? NSBatchDeleteResult
            let ids = result?.result as? [NSManagedObjectID] ?? []
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [context])
        } catch {
            log("Error deleting devices: \(error.localizedDescription)", caller: "DeviceManager")
        }
        
        pairedDevice = nil
        fetchAllDevices()
    }
}

extension DeviceManager {
    func updateInfo(characteristic: CBCharacteristic) {
        guard let value = characteristic.value else { return }

        let context = persistenceController.container.viewContext

        context.perform {
            guard let device = self.currentDevice(in: context) else { return }

            switch characteristic.uuid {
            case BLEUUID.modelNumber:
                device.modelNumber = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.serial:
                device.serial = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.firmware:
                device.firmware = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.hardwareRevision:
                device.hardwareRevision = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.softwareRevision:
                device.softwareRevision = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.manufacturer:
                device.manufacturer = String(data: value, encoding: .utf8) ?? ""
            case BLEUUID.blefsVersion:
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

            if characteristic.uuid == BLEUUID.firmware {
                // Faces depend on the firmware version
                self.objectWillChange.send()
                WatchFaceCatalog.shared.objectWillChange.send()
                DownloadManager.shared.evaluateFirmwareUpdate()
            }
        }
    }
    
    func readInfoCharacteristics(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        switch characteristic.uuid {
        case BLEUUID.modelNumber, BLEUUID.serial, BLEUUID.firmware, BLEUUID.hardwareRevision, BLEUUID.softwareRevision, BLEUUID.manufacturer, BLEUUID.blefsVersion: peripheral.readValue(for: characteristic)
        default:
            break
        }
    }
}

extension Settings {
    init(device: Device) {
        self.init()
        
        version = UInt32(clamping: device.settingsVersion)
        stepsGoal = UInt32(clamping: device.stepsGoal)
        screenTimeOut = UInt32(clamping: device.screenTimeout)
        alwaysOnDisplay = device.alwaysOnDisplay
        clockType = ClockType(rawValue: UInt8(clamping: device.clockType)) ?? .H24
        weatherFormat = WeatherFormat(rawValue: UInt8(clamping: device.weatherFormat)) ?? .Metric
        notificationStatus = Notification(rawValue: UInt8(clamping: device.notificationStatus)) ?? .On
        watchFace = UInt8(clamping: device.watchface)
        chimesOption = ChimesOption(rawValue: UInt8(clamping: device.chimesOption)) ?? .None
        shakeWakeThreshold = UInt16(clamping: device.shakeWakeThreshold)
        brightLevel = BrightLevel(rawValue: UInt8(clamping: device.brightLevel)) ?? .Mid
        prideFlag = UInt8(clamping: device.prideFlag)
        
        if let pts = device.pineTimeStyle {
            pineTimeStyle = PineTimeStyleData(
                ColorTime: Colors(rawValue: UInt8(clamping: pts.colorTime)) ?? .Teal,
                ColorBar: Colors(rawValue: UInt8(clamping: pts.colorBar)) ?? .Teal,
                ColorBG: Colors(rawValue: UInt8(clamping: pts.colorBG)) ?? .Black,
                gaugeStyle: PTSGaugeStyle(rawValue: UInt8(clamping: pts.guageStyle)) ?? .Full,
                weatherEnable: PTSWeather(rawValue: UInt8(clamping: pts.weatherEnable)) ?? .Off
            )
        }
        if let infineat = device.watchFaceInfineat {
            watchFaceInfineat = WatchFaceInfineat(showSideCover: infineat.showSideCover, colorIndex: UInt8(clamping: infineat.colorIndex))
        }
    }
}
