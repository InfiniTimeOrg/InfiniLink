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
    @Published var blefsTransfer: CBCharacteristic?
    @Published var currentTimeService: CBCharacteristic?
    var notifyCharacteristic: CBCharacteristic?
    var weatherCharacteristic: CBCharacteristic?
    
    var dfuControlPointCharacteristic: CBCharacteristic?
    var dfuPacketCharacteristic: CBCharacteristic?
    
    @Published var navigationFlagsCharacteristic: CBCharacteristic?
    @Published var navigationNarrativeCharacteristic: CBCharacteristic?
    @Published var navigationDistanceCharacteristic: CBCharacteristic?
    @Published var navigationProgressCharacteristic: CBCharacteristic?
    
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
//        let sleep = CBUUID(string: "2037")
        let blefsTransfer = CBUUID(string: "adaf0200-4669-6c65-5472-616e73666572")
        let motion = CBUUID(string: "00030002-78fc-48fe-8e23-433b3a1942d0")
        let weather = CBUUID(string: "00050001-78FC-48FE-8E23-433B3A1942D0")
        
        let dfuService = CBUUID(string: "00001530-1212-efde-1523-785feabcd123")
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
    @Published var isUpdatingFirmware = false
    @Published var isReconnectingAfterUpdate = false // The transfer finished; the watch reboots to install it
    @Published var ancsAuthorized = false // We don't need to persist this, it only matters when we're connected
    
    @Published var newPeripherals: [CBPeripheral] = []
    @Published var discoveredRSSI: [UUID: Int] = [:]
    @Published var infiniTime: CBPeripheral?
    @Published var peripheralToConnect: CBPeripheral?
    
    @Published var hasLoadedBatteryLevel = false
    @Published var fakeRecoveryMode = false // Developer toggle
    
    @Published var heartRate: Double = 0
    @Published var batteryLevel: Double = 0
    @Published var stepCount: Int = 0
    @Published var rssi: Int?
    
    @Published var error: String = ""
    @Published var showError: Bool = false
    
    @Published var disconnectCount = 0
    @Published var lastDisconnectReason: String?
    @Published var lastDisconnectDate: Date?
    var lastDataReceivedDate: Date?
    private var lastSeenSavedDate: Date?
    
    @AppStorage("pauseOnWalkaway") var pauseOnWalkaway = true
    @AppStorage("forceAncs") var forceAncs = true
    
    var hasLoadedCharacteristics: Bool {
        return currentTimeService != nil && isConnectedToPinetime // Use currentTimeService because it's present in all firmware versions
    }
    var isDeviceInRecoveryMode: Bool {
        return fakeRecoveryMode || deviceManager.firmware.components(separatedBy: ".").first == "0"
    }
    // Only while the watch is disconnected and rebooting to install
    var isInstallingUpdate: Bool {
        return isReconnectingAfterUpdate && !isConnectedToPinetime
    }
    var isBusy: Bool {
        return isConnecting || (isScanning && !isPairingNewDevice)
    }
    var connectionState: String {
        if isInstallingUpdate {
            return NSLocalizedString("Installing update...", comment: "")
        }
        if (isUpdatingFirmware || isReconnectingAfterUpdate) && !isDeviceInRecoveryMode { // Recovery shows progress in its banner
            return NSLocalizedString("Updating...", comment: "")
        }
        if isBusy {
            return NSLocalizedString("Connecting...", comment: "")
        }
        switch (isConnectedToPinetime, hasLoadedBatteryLevel) {
        case (true, true):
            return NSLocalizedString("Connected", comment: "")
        case (true, false):
            return NSLocalizedString("Connecting...", comment: "")
        default:
            return NSLocalizedString("Disconnected", comment: "")
        }
    }
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self,
                                   queue: nil,
                                   options: [
                                    CBCentralManagerOptionRestoreIdentifierKey: "com.alex-emry.Infini-iOS.central"
                                   ])
    }
    
    func scanForNewDevices() {
        guard !isScanning else { return }
        
        manager?.scanForPeripherals(withServices: nil, options: nil)
        newPeripherals = []
        discoveredRSSI = [:]
        isScanning = true
    }
    
    func startScanning() {
        guard manager?.state == .poweredOn else { return }
        
        if let id = deviceManager.pairedDeviceID,
           let uuid = UUID(uuidString: id), !isPairingNewDevice { // The user has a paired device and they're not trying to pair a new one
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
        
        let options: [String: Any] = [
            CBConnectPeripheralOptionRequiresANCS: true
        ]
        self.manager?.connect(peripheralToConnect!, options: forceAncs ? options : nil)

        completion?()
    }

    func onConnect(_ peripheral: CBPeripheral) {
        isReconnectingAfterUpdate = false
        stopScanning()
        
        if deviceManager.pairedDeviceID != peripheral.identifier.uuidString { // Only clear the update for a new device
            downloadManager.clearUpdate()
        }
        
        isConnecting = false
        deviceManager.pairedDeviceID = peripheral.identifier.uuidString
        deviceManager.pairedDevice = deviceManager.currentDevice()
        
        infiniTime = peripheral
        infiniTime?.delegate = self
        infiniTime?.discoverServices(nil)
        isConnectedToPinetime = true
        peripheralToConnect = nil // We're done using this, so set it to nil
        saveLastSeen(peripheral)
        
        updateAncsStatus(peripheral)
        
        log("Connected to \(deviceManager.pairedDevice?.name ?? "InfiniTime")", type: .info, caller: "BLEManager", target: .ble)
    }
    
    func unpair(device: Device? = nil) {
        guard let device = device ?? deviceManager.pairedDevice else { return }
        
        // We need to disconnect first because BLE updateInfo methods will be called when Core Data doesn't have an object to update
        disconnect()
        // Delete the device object we have said for this watch
        deviceManager.removeDevice(device)
        
        log("Unpaired from \(deviceManager.pairedDevice?.name ?? "InfiniTime")", type: .info, caller: "BLEManager", target: .ble)
    }
    
    func disconnect() {
        isReconnectingAfterUpdate = false

        if let infiniTime = infiniTime {
            self.manager?.cancelPeripheralConnection(infiniTime)
            
            // Update the rest of the app to reflect the disconnected state
            self.infiniTime = nil
            self.clearCharacteristics()
            self.hasLoadedBatteryLevel = false
            self.isConnectedToPinetime = false
            
            log("Disconnected", type: .info, caller: "BLEManager", target: .ble)
        }
    }
    
    func beginFirmwareUpdate() {
        isUpdatingFirmware = true
    }
    
    func endFirmwareUpdate(installed: Bool = false) {
        isUpdatingFirmware = false
        isReconnectingAfterUpdate = installed
        // If we're still connected, the watch restarting disconnects and we reconnect on our own
        if !isConnectedToPinetime {
            startScanning()
        }

        if installed {
            // Don't sit on "Installing update..." forever if the watch never comes back
            DispatchQueue.main.asyncAfter(deadline: .now() + 90) { [weak self] in
                self?.isReconnectingAfterUpdate = false
            }
        }
    }
    
    func switchDevice(device: Device) {
        // We just switched devices, update the UI
        self.deviceManager.pairedDeviceID = device.uuid
        self.deviceManager.pairedDevice = device
//        self.deviceManager.
        
        self.disconnect()
        self.startScanning()
    }
    
    // Drop every characteristic from the old connection so nothing writes to a stale peripheral
    private func clearCharacteristics() {
        blefsTransfer = nil
        currentTimeService = nil
        notifyCharacteristic = nil
        weatherCharacteristic = nil
        dfuControlPointCharacteristic = nil
        dfuPacketCharacteristic = nil
        navigationFlagsCharacteristic = nil
        navigationNarrativeCharacteristic = nil
        navigationDistanceCharacteristic = nil
        navigationProgressCharacteristic = nil
        musicChars = MusicCharacteristics()
    }
    
    func lastSeenDate(for uuid: String?) -> Date? {
        guard let uuid, let dates = UserDefaults.standard.dictionary(forKey: "lastSeenDates") as? [String: Double], let timestamp = dates[uuid] else { return nil }
        
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func saveLastSeen(_ peripheral: CBPeripheral) {
        var dates = UserDefaults.standard.dictionary(forKey: "lastSeenDates") as? [String: Double] ?? [:]
        dates[peripheral.identifier.uuidString] = Date().timeIntervalSince1970
        UserDefaults.standard.set(dates, forKey: "lastSeenDates")
        
        lastSeenSavedDate = Date()
    }
    
    private func updateAncsStatus(_ peripheral: CBPeripheral) {
        self.ancsAuthorized = peripheral.ancsAuthorized
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard !isUpdatingFirmware else { return }
        
        if deviceManager.pairedDeviceID == peripheral.identifier.uuidString && !isPairingNewDevice {
            connect(peripheral: peripheral)
        }
        // InfiniTime always advertises the name "InfiniTime" along with its DFU service, so require both
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        let advertisedServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        guard name == "InfiniTime" && advertisedServices.contains(cbuuidList.dfuService) else { return }
        
        if RSSI.intValue != 127 { // 127 means the value is unavailable
            discoveredRSSI[peripheral.identifier] = RSSI.intValue
        }
        if !newPeripherals.contains(where: { $0.identifier == peripheral.identifier }) && !deviceManager.watches.contains(where: { $0.uuid ?? "" == peripheral.identifier.uuidString }) { // The peripheral has not already been discovered
            newPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.isConnecting = false
        
        guard !isUpdatingFirmware else { return }
        
        if let error {
            log("Failed to connect to peripheral: \(error.localizedDescription)", caller: "BLEManager", target: .ble)
            
            if (error as? CBError)?.code == .peerRemovedPairingInformation {
                self.error = NSLocalizedString("InfiniLink could not connect to your device because the bond is no longer present. Please remove the watch from Bluetooth settings to reconnect.", comment: "")
                self.showError = true
                
                return
            }
        }
        
        connect(peripheral: peripheral) // The connection was abruptly terminated, so we try connecting again
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        onConnect(peripheral) // The connection was successfully, update state vars and start service discovery
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnectedToPinetime = false
        notifyCharacteristic = nil
        
        disconnectCount += 1
        lastDisconnectDate = Date()
        lastDisconnectReason = error?.localizedDescription
        saveLastSeen(peripheral)
        HealthKitManager.shared.flushHeartRateSamples()
        NotificationManager.shared.resetActivityCheck()
        DFUUpdater.shared.transfer?.connectionLost()
        
        // Drop the stale peripheral so in-flight BLEFS loops become no-ops and state can't half-persist
        infiniTime = nil
        clearCharacteristics()
        hasLoadedBatteryLevel = false
        
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
        
        if isBluetoothOn && !isConnectedToPinetime && !isUpdatingFirmware {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        willRestoreState dict: [String : Any]) {
        guard !isUpdatingFirmware else { return }
        
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
        log("ANCS authorization status changed: \(peripheral.ancsAuthorized)", type: .info, target: .ble)
        updateAncsStatus(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            deviceManager.readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
            BLECharacteristicHandler.shared.handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            log(error!.localizedDescription, caller: "didUpdateValueFor characteristic", target: .ble)
            return
        }
        
        if characteristic.uuid == cbuuidList.dfuControlPoint, let value = characteristic.value {
            DFUUpdater.shared.transfer?.didReceiveControlPoint(value)
            return
        }
        
        lastDataReceivedDate = Date()
        // Keep the last seen date current without writing it on every update
        if Date().timeIntervalSince(lastSeenSavedDate ?? .distantPast) > 60 {
            saveLastSeen(peripheral)
        }
        
        deviceManager.updateInfo(characteristic: characteristic)
        BLECharacteristicHandler.shared.handleUpdates(characteristic: characteristic, peripheral: peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == cbuuidList.dfuControlPoint {
            DFUUpdater.shared.transfer?.didWriteControlPoint(error: error)
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        DFUUpdater.shared.transfer?.peripheralIsReady()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error {
            print(error.localizedDescription)
        }
        
        self.rssi = RSSI.intValue
    }
}
