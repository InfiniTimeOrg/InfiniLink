//
//  BLEManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/2024.
//

import Foundation
import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BLEManager()
    
    lazy var deviceManager = DeviceManager.shared
    
    var central: CBCentralManager!
    var blefsTransfer: CBCharacteristic!
    var currentTimeService: CBCharacteristic!
    var notifyCharacteristic: CBCharacteristic!
    var weatherCharacteristic: CBCharacteristic!
    
    struct MusicCharacteristics {
        var control: CBCharacteristic!
        var track: CBCharacteristic!
        var artist: CBCharacteristic!
        var status: CBCharacteristic!
        var position: CBCharacteristic!
        var length: CBCharacteristic!
    }
    struct CBUUIDList {
        let hrm = CBUUID(string: "2A37")
        let bat = CBUUID(string: "2A19")
        let time = CBUUID(string: "2A2B")
        let notify = CBUUID(string: "2A46")
        let modelNumber = CBUUID(string: "2A24")
        let serial = CBUUID(string: "2A25")
        let firmware = CBUUID(string: "2A26")
        let hardwareRevision = CBUUID(string: "2A27")
        let softwareRevision = CBUUID(string: "2A28")
        let manufacturer = CBUUID(string: "2A29")
        let blefsTransfer = CBUUID(string: "adaf0200-4669-6c65-5472-616e73666572")
        let motion = CBUUID(string: "00030002-78fc-48fe-8e23-433b3a1942d0")
        let weather = CBUUID(string: "00050001-78FC-48FE-8E23-433B3A1942D0")
        let musicControl = CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")
        let statusControl = CBUUID(string: "00000002-78FC-48FE-8E23-433B3A1942D0")
        let musicTrack = CBUUID(string: "00000004-78FC-48FE-8E23-433B3A1942D0")
        let musicArtist = CBUUID(string: "00000003-78FC-48FE-8E23-433B3A1942D0")
        let stepCount = CBUUID(string: "00030001-78FC-48FE-8E23-433B3A1942D0")
        let positionTrack = CBUUID(string: "00000006-78FC-48FE-8E23-433B3A1942D0")
        let lengthTrack = CBUUID(string: "00000007-78FC-48FE-8E23-433B3A1942D0")
    }
    
    let cbuuidList = CBUUIDList()
    var musicChars = MusicCharacteristics()
    
    @Published var isSwitchedOn = false
    @Published var isScanning = false
    @Published var setTimeError = false
    @Published var isConnectedToPinetime = false
    @Published var isPairingNewDevice = false
    
    @Published var newPeripherals: [CBPeripheral] = []
    @Published var infiniTime: CBPeripheral!
    
    @Published var weatherInformation = WeatherInformation()
    @Published var weatherForecastDays = [WeatherForecastDay]()
    @Published var loadingWeather = true
    @Published var hasLoadedBatteryLevel = false
    
    @Published var heartRate: Double = 0
    @Published var batteryLevel: Double = 0
    @Published var stepCount: Int = 0
    
    @Published var pairedDevice: Device!
    
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    
    var hasLoadedCharacteristics: Bool {
        // Use currentTimeService because it's present in all firmware versions
        return currentTimeService != nil && isConnectedToPinetime
    }
    var isHeartRateBeingRead: Bool {
        return heartRate != 0
    }
    var isDeviceInRecoveryMode: Bool {
        let first = deviceManager.firmware.components(separatedBy: ".").first
        
        return first == "0"
    }
    
    override init() {
        super.init()
        self.central = CBCentralManager(delegate: self, queue: nil)
        
        self.startScanning()
    }
    
    func startScanning() {
        guard central.state == .poweredOn else { return }
        
        central.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        newPeripherals = []
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        central.stopScan()
        isScanning = false
    }
    
    func connect(peripheral: CBPeripheral, completion: @escaping() -> Void) {
        guard isSwitchedOn else { return }
        
        if peripheral.name == "InfiniTime" {
            if isConnectedToPinetime {
                disconnect()
            }
            stopScanning()
            
            DownloadManager.shared.updateAvailable = false
            pairedDevice = deviceManager.fetchDevice(with: peripheral.identifier.uuidString)
            
            infiniTime = peripheral
            infiniTime?.delegate = self
            central.connect(peripheral, options: nil)
            
            completion()
        }
    }
    
    func removeDevice() {
        deviceManager.removeDevice(pairedDevice)
        unpair()
    }
    
    func resetDevice() {
        BLEFSHandler.shared.writeSettings(Settings())
        deviceManager.settings = Settings()
    }
    
    func unpair() {
        disconnect()
        if let pairedDevice {
            deviceManager.removeDevice(pairedDevice)
        }
        deviceManager.fetchAllDevices()
        if let first = deviceManager.watches.first, deviceManager.watches.count > 1 {
            pairedDeviceID = first.uuid
            pairedDevice = deviceManager.fetchDevice()
        } else {
            pairedDeviceID = nil
        }
        startScanning()
    }
    
    func disconnect() {
        if let infiniTime = infiniTime {
            self.central.cancelPeripheralConnection(infiniTime)
            self.infiniTime = nil
            self.blefsTransfer = nil
            self.currentTimeService = nil
            self.notifyCharacteristic = nil
            self.hasLoadedBatteryLevel = false
            self.isConnectedToPinetime = false
        }
    }
    
    func switchDevice(device: Device) {
        self.disconnect()
        self.pairedDeviceID = device.uuid
        self.pairedDevice = deviceManager.fetchDevice()
        self.deviceManager.getSettings()
        self.startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pairedDeviceID = pairedDeviceID, pairedDeviceID == peripheral.identifier.uuidString && !isPairingNewDevice {
            connect(peripheral: peripheral) {}
        }
        if peripheral.name == "InfiniTime" && !newPeripherals.contains(where: { $0.identifier.uuidString == peripheral.identifier.uuidString }) {
            
            if isPairingNewDevice {
                if !deviceManager.watches.compactMap({ $0.uuid }).contains(peripheral.identifier.uuidString) {
                    newPeripherals.append(peripheral)
                }
            } else {
                newPeripherals.append(peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Failed to connect to peripheral: \(error.localizedDescription)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.infiniTime.discoverServices(nil)
        self.isConnectedToPinetime = true
        self.pairedDeviceID = peripheral.identifier.uuidString
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnectedToPinetime = false
        notifyCharacteristic = nil
        
        if error != nil {
            central.connect(peripheral)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isSwitchedOn = (central.state == .poweredOn)
        if isSwitchedOn && !isConnectedToPinetime {
            startScanning()
        }
    }
    
    // MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            if let error {
                print(error.localizedDescription)
            }
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            deviceManager.readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
            BLEDiscoveredCharacteristics().handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        deviceManager.updateInfo(characteristic: characteristic)
        BLEUpdatedCharacteristicHandler().handleUpdates(characteristic: characteristic, peripheral: peripheral)
    }
}
