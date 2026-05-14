//
//  BLEManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/2024.
//

import Foundation
import CoreBluetooth
import SwiftUI
import CoreLocation

class BLEManager: NSObject, ObservableObject {
    static let shared = BLEManager()
    
    lazy var deviceManager = DeviceManager.shared // This references BLEManager so it needs to be lazy to avoid a crash
    
    let locationManager = LocationManager.shared
    let downloadManager = DownloadManager.shared
    let persistenceController =  PersistenceController.shared
    
    var manager: CBCentralManager?
    var blefsTransfer: CBCharacteristic?
    var currentTimeService: CBCharacteristic?
    var notifyCharacteristic: CBCharacteristic?
    var weatherCharacteristic: CBCharacteristic?
    
    var dfuControlPointCharacteristic: CBCharacteristic?
    var dfuPacketCharacteristic: CBCharacteristic?
    
    var navigationFlagsCharacteristic: CBCharacteristic?
    var navigationNarrativeCharacteristic: CBCharacteristic?
    var navigationDistanceCharacteristic: CBCharacteristic?
    var navigationProgressCharacteristic: CBCharacteristic?
    
    struct MusicCharacteristics {
        var control: CBCharacteristic?
        var track: CBCharacteristic?
        var artist: CBCharacteristic?
        var status: CBCharacteristic?
        var position: CBCharacteristic?
        var length: CBCharacteristic?
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
        let sleep = CBUUID(string: "2037")
        let blefsTransfer = CBUUID(string: "adaf0200-4669-6c65-5472-616e73666572")
        let motion = CBUUID(string: "00030002-78fc-48fe-8e23-433b3a1942d0")
        let weather = CBUUID(string: "00050001-78FC-48FE-8E23-433B3A1942D0")
        
        let dfuControlPoint = CBUUID(string: "00001531-1212-efde-1523-785feabcd123")
        let dfuPacket = CBUUID(string: "00001532-1212-efde-1523-785feabcd123")
        
        // We don't need the navigation service UUID, just its characteristics
        // let navigation = CBUUID(string: "00010000-78fc-48fe-8e23-433b3a1942d0")
        let navigationFlags = CBUUID(string: "00010001-78fc-48fe-8e23-433b3a1942d0")
        let navigationNarrative = CBUUID(string: "00010002-78fc-48fe-8e23-433b3a1942d0")
        let navigationDistance = CBUUID(string: "00010003-78fc-48fe-8e23-433b3a1942d0")
        let navigationProgress = CBUUID(string: "00010004-78fc-48fe-8e23-433b3a1942d0")
        
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
    
    @Published var isBluetoothOn = true // Keep this variable initally true because otherwise it could quickly flash the "Bluetooth Disabled" message
    @Published var isScanning = false
    @Published var isConnecting = false
    @Published var setTimeError = false
    @Published var isConnectedToPinetime = false
    @Published var isPairingNewDevice = false
    @Published var hasDisconnectedForUpdate = false
    @Published var ancsAuthorized = false // We don't need to persist this, it only matters when we're connected
    
    @Published var newPeripherals: [CBPeripheral] = []
    @Published var infiniTime: CBPeripheral?
    @Published var peripheralToConnect: CBPeripheral?
    
    @Published var hasLoadedBatteryLevel = false
    
    @Published var heartRate: Double = 0
    @Published var batteryLevel: Double = 0
    @Published var stepCount: Int = 0
    @Published var rssi: Int?
    
    @Published var error: String = ""
    @Published var showError: Bool = false
    
    @Published var pairedDevice: Device!
    
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    @AppStorage("pauseOnWalkaway") var pauseOnWalkaway = true
    
    var hasLoadedCharacteristics: Bool {
        return currentTimeService != nil && isConnectedToPinetime // Use currentTimeService because it's present in all firmware versions
    }
    var isDeviceInRecoveryMode: Bool {
        return deviceManager.firmware.components(separatedBy: ".").first == "0"
    }
    var isBusy: Bool {
        return isConnecting || (isScanning && !isPairingNewDevice)
    }
    var connectionState: String {
        if isBusy {
            return NSLocalizedString("Connecting...", comment: "")
        }
        switch (isConnectedToPinetime, hasLoadedBatteryLevel) {
        case (true, true):
            return NSLocalizedString("Connected", comment: "")
        case (true, false):
            return NSLocalizedString("Connecting...", comment: "")
        default:
            if hasDisconnectedForUpdate {
                return NSLocalizedString("Installing update...", comment: "")
            } else {
                return NSLocalizedString("Disconnected", comment: "")
            }
        }
    }
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self,
                                   queue: nil,
                                   options: [
                                    CBPeripheralManagerOptionRestoreIdentifierKey: "com.alex-emry.Infini-iOS.central"
                                   ])
    }
    
    func scanForNewDevices() {
        guard !isScanning else { return }
        
        manager?.scanForPeripherals(withServices: nil, options: nil)
        newPeripherals = []
        isScanning = true
    }
    
    func startScanning() {
        guard manager?.state == .poweredOn else { return }
        
        if let pairedDeviceID = pairedDeviceID,
           let uuid = UUID(uuidString: pairedDeviceID), !isPairingNewDevice { // The user has a paired device and they're not trying to pair a new one
            let peripherals = manager?.retrievePeripherals(withIdentifiers: [uuid])
            log("\(peripherals ?? [])", type: .info, caller: "BLEManager - startScanning")
            
            if let peripheral = peripherals?.first, !isConnectedToPinetime {
                connect(peripheral: peripheral)
            } else {
                scanForNewDevices()
            }
        } else {
            scanForNewDevices()
        }
    }
    
    func stopScanning() {
        manager?.stopScan()
        isScanning = false
    }
    
    func connect(peripheral: CBPeripheral, completion: (() -> Void)? = nil) {
        guard isBluetoothOn else { return }
        
        self.isConnecting = true
        self.peripheralToConnect = peripheral
        self.manager?.connect(peripheralToConnect!, options: nil)
        
        completion?()
    }
    
    func onConnect(_ peripheral: CBPeripheral) {
        stopScanning()
        
        if pairedDeviceID != peripheral.identifier.uuidString { // Only clear the update for a new device
            downloadManager.clearUpdate()
        }
        
        isConnecting = false
        pairedDeviceID = peripheral.identifier.uuidString
        pairedDevice = deviceManager.fetchDevice(with: peripheral.identifier.uuidString)
        hasDisconnectedForUpdate = false
        
        infiniTime = peripheral
        infiniTime?.delegate = self
        infiniTime?.discoverServices(nil)
        isConnectedToPinetime = true
        peripheralToConnect = nil // We're done using this, so set it to nil
        
        updateAncsStatus(peripheral)
        
        log("Connected to \(pairedDevice?.name ?? "InfiniTime")", type: .info, caller: "BLEManager", target: .ble)
    }
    
    func unpair(device: Device? = nil) {
        // We need to disconnect first because BLE updateInfo methods will be called when Core Data doesn't have an object to update
        disconnect()
        // Delete the device object we have said for this watch
        deviceManager.removeDevice(device ?? pairedDevice!)
        
        log("Unpaired from \(pairedDevice?.name ?? "InfiniTime")", type: .info, caller: "BLEManager", target: .ble)
    }
    
    func disconnect() {
        if let infiniTime = infiniTime {
            self.manager?.cancelPeripheralConnection(infiniTime)
            
            // Update the rest of the app to reflect the disconnected state
            self.infiniTime = nil
            self.blefsTransfer = nil
            self.currentTimeService = nil
            self.notifyCharacteristic = nil
            self.hasLoadedBatteryLevel = false
            self.isConnectedToPinetime = false
            
            log("Disconnected", type: .info, caller: "BLEManager", target: .ble)
        }
    }
    
    func switchDevice(device: Device) {
        // We just switched devices, update the UI
        self.pairedDeviceID = device.uuid
        self.pairedDevice = device
        self.deviceManager.setSettings()
        
        self.disconnect()
        self.startScanning()
    }
    
    private func updateAncsStatus(_ peripheral: CBPeripheral) {
        self.ancsAuthorized = peripheral.ancsAuthorized
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pairedDeviceID, pairedDeviceID == peripheral.identifier.uuidString && !isPairingNewDevice {
            connect(peripheral: peripheral)
        }
        if peripheral.name == "InfiniTime" && !newPeripherals.contains(where: { $0.identifier == peripheral.identifier }) && !deviceManager.watches.contains(where: { $0.uuid! == peripheral.identifier.uuidString }) { // The peripheral has not already been discovered
            newPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.isConnecting = false
        
        if let error = error {
            log("Failed to connect to peripheral: \(error.localizedDescription)", caller: "BLEManager", target: .ble)
            
            // We can't do anything like check an error code, so this is sufficient for a "bond removed" message
            // Won't work when language is not English? (localizedDescription)
            if error.localizedDescription.contains("removed pairing information") {
                self.error = NSLocalizedString("InfiniLink could not connect to your device because the bond is no longer present. Please remove the watch from Bluetooth settings to reconnect.", comment: "")
                self.showError = true
                
                return
            }
        }
        
        // The connection was abruptly terminated, so we try connecting again
        connect(peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // The connection was successfully, update state vars and start service discovery
        onConnect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnectedToPinetime = false
        notifyCharacteristic = nil
        
        if let error {
            log(error.localizedDescription, caller: "didDisconnectPeripheral", target: .ble)
            
            if let rssi, RSSI.from(rssi: rssi) == RSSI.poor { // Make sure the disconnect was a range issue
                if pauseOnWalkaway { // The watch went out of range, pause any currently playing music
                    MusicController.shared.pause()
                }
                
                if let point = ChartManager.shared.disconnectMapPoint(), let lon = locationManager.location?.coordinate.longitude, let lat = locationManager.location?.coordinate.latitude {
                    point.latitude = lat
                    point.longitude = lon
                    point.timestamp = Date()
                    
                    persistenceController.save()
                }
            }
            
            // Try reconnecting to the watch
            connect(peripheral: peripheral)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothOn = (central.state == .poweredOn)
        isConnecting = false
        isScanning = false
        
        if !isBluetoothOn {
            disconnect()
        }
        
        if isBluetoothOn && !isConnectedToPinetime {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                log("Restored peripheral: \(peripheral.identifier)", type: .info, caller: "willRestoreState")
                self.connect(peripheral: peripheral)
            }
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            if let error {
                log("Error discovering services: \(error.localizedDescription)", caller: "BLEManager", target: .ble)
            }
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        updateAncsStatus(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            deviceManager.readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
            BLECharacteristicHandler().handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log(error!.localizedDescription, caller: "didUpdateValueFor characteristic", target: .ble)
            return
        }
        
        deviceManager.updateInfo(characteristic: characteristic)
        BLECharacteristicHandler().handleUpdates(characteristic: characteristic, peripheral: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error {
            print(error.localizedDescription)
        }
        
        self.rssi = RSSI.intValue
    }
}
