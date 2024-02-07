//
//  BLEManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/3/21.
//

import Foundation
import CoreBluetooth
import SwiftUICharts
import SwiftUI


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    
   static let shared = BLEManager()
    
    var myCentral: CBCentralManager!
    var blefsTransfer: CBCharacteristic!
    
    struct musicCharacteristics {
        var control: CBCharacteristic!
        var track: CBCharacteristic!
        var artist: CBCharacteristic!
        var status: CBCharacteristic!
        var position: CBCharacteristic!
        var length: CBCharacteristic!
    }
    
    struct Peripheral: Identifiable {
        let id: Int
        let name: String
        let rssi: Int
        let peripheralHash: Int
        let deviceUUID: CBUUID
        let stringUUID: String
    }
    
    struct cbuuidList {
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
        let weather =       CBUUID(string: "00050001-78FC-48FE-8E23-433B3A1942D0")
        let musicControl =  CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")
        let statusControl = CBUUID(string: "00000002-78FC-48FE-8E23-433B3A1942D0")
        let musicTrack = CBUUID(string: "00000004-78FC-48FE-8E23-433B3A1942D0")
        let musicArtist = CBUUID(string: "00000003-78FC-48FE-8E23-433B3A1942D0")
        let stepCount = CBUUID(string: "00030001-78FC-48FE-8E23-433B3A1942D0")
        let positionTrack = CBUUID(string: "00000006-78FC-48FE-8E23-433B3A1942D0")
        let lengthTrack = CBUUID(string: "00000007-78FC-48FE-8E23-433B3A1942D0")
    }
    
//    let cbuuidList = cbuuidList()
//    var musicChars = musicCharacteristics()
//
//    let settings = UserDefaults.standard
    
    
    // UI flag variables
    @Published var isSwitchedOn = false                                    // for now this is used to display if bluetooth is on in the main app screen. maybe an alert in the future?
    @Published var isScanning = false                                    // another UI flag. Probably not necessary for anything but debugging. I dunno maybe a little swirly animation or something could be triggered by this
    @Published var isConnectedToPinetime = false                        // another flag published to update UI stuff. Can probably be implemented better in the future
//    @Published var heartBPM: Double = 0                                    // published var to communicate the HRM data to the UI.
    @Published var batteryLevel: Double = 0                                // Same as heartBPM but for battery data
//    @Published var firmwareVersion: String = "Disconnected"
    @Published var setTimeError = false
    @Published var blePermissions: Bool!
    
//    @Published var stepCount: Int = 0
//    @Published var stepCounting: Int = 0

    // Selecting and connecting variables
    @Published var peripherals = [Peripheral]()
    @Published var newPeripherals: [CBPeripheral] = []                    // used to print human-readable device names to UI in selection process
//    @Published var deviceToConnect: Int!                                // When the user selects a device from the UI, that peripheral's ID goes in this var, which is passed to the peripheralDictionary
    @Published var peripheralDictionary: [Int: CBPeripheral] = [:]         // this is the dictionary that relates human-readable peripheral names to the CBPeripheral class that CoreBluetooth actually interacts with
    @Published var infiniTime: CBPeripheral!                            // variable to save the CBPeripheral that you're connecting to
//    @Published var autoconnectPeripheral: CBPeripheral!
    @Published var setAutoconnectUUID: String = ""                            // placeholder for now while I figure out how to save the whole device in UserDefaults to save "favorite" devices
    
    @Published var bleLogger = DebugLogManager.shared // MARK: logging

    var firstConnect: Bool = true                                        // makes iOS connected message only show up on first connect, not if device drops connection and reconnects
    var disconnected: Bool = false
    var heartChartReconnect: Bool = true                                // skip first HRM transmission on every fresh connection to prevent saving of BS data
//    var batChartReconnect: Bool = true                                // skip first HRM transmission on every fresh connection to prevent saving of BS data
    
    // declare some CBUUIDs for easier reference
    @Published var autoconnectToDevice: Bool = false

    
    override init() {
        super.init()

        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
        if myCentral.state == .unauthorized {
            blePermissions = false
        } else {
            blePermissions = true
        }
    }
    
    func startScanning() {
        myCentral.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        peripherals = [Peripheral]()
        peripheralDictionary = [:]
        newPeripherals = []
    }
    
    func stopScanning() {
        myCentral.stopScan()
        isScanning = false
    }
    
    func disconnect(){
        if infiniTime != nil {
            disconnected = true
            myCentral.cancelPeripheralConnection(infiniTime)
            firstConnect = true
            isConnectedToPinetime = false
            heartChartReconnect = false
            infiniTime = nil
        }
    }
    
    func connect(peripheral: CBPeripheral) {
        // Still blocking connections to anything not named "InfiniTime" until I can set up a proper way to test other devices
        
        if peripheral.name == "InfiniTime" || peripheral.name == "Pinetime-JF" {
            if isConnectedToPinetime == true {
                self.myCentral.cancelPeripheralConnection(self.infiniTime)
            }
            disconnected = false
            self.myCentral.stopScan()
            isScanning = false
            
            self.infiniTime = peripheral
            infiniTime.delegate = self
            self.myCentral.connect(peripheral, options: nil)
            
            setAutoconnectUUID = peripheral.identifier.uuidString
            isConnectedToPinetime = true
            autoconnectToDevice = (autoconnectUUID == setAutoconnectUUID)
            //autoconnectUUID == bleManager.setAutoconnectUUID
        } else {
            DebugLogManager.shared.debug(error: "Could not connect to device not named 'InfiniTime'. Device name: \(peripheral.name!)", log: .ble, date: Date())
        }
    }
        
    

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
//        var peripheralName: String!
        if let _ = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
//            peripheralName = name
//            let devUUIDString: String = peripheral.identifier.uuidString
//            let devUUID: CBUUID = CBUUID(string: devUUIDString)
//            let newPeripheral = Peripheral(id: peripheralDictionary.count, name: peripheralName, rssi: RSSI.intValue, peripheralHash: peripheral.hash, deviceUUID: devUUID, stringUUID: peripheral.identifier.uuidString)
            if isConnectedToPinetime == false {
                guard BLEAutoconnectManager.shared.connect(peripheral: peripheral) else {
//                if !peripherals.contains(where: {$0.deviceUUID == newPeripheral.deviceUUID}) {
//                    peripherals.append(newPeripheral)
//                    peripheralDictionary[newPeripheral.peripheralHash] = peripheral
//                }
                    if !newPeripherals.contains(where: {$0.identifier.uuidString == peripheral.identifier.uuidString}) {
                        newPeripherals.append(peripheral)
                    }
                    return
                }
            } else {
                if !newPeripherals.contains(where: {$0.identifier.uuidString == peripheral.identifier.uuidString}) {
                    newPeripherals.append(peripheral)
                }
                return
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            bleLogger.debug(error: "Failed to connect: \(error!)", log: .ble, date: Date()) // MARK: logging
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.infiniTime.discoverServices(nil)
        DeviceInfoManager().setDeviceName(uuid: peripheral.identifier.uuidString)
        UptimeManager.shared.connectTime = Date()
        bleLogger.debug(error: "Successfully connected to \(peripheral.name!)", log: .ble, date: Date())
        ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: 1, chart: ChartsAsInts.connected.rawValue))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            heartChartReconnect = true
            //connect(peripheral: peripheral)
            central.connect(peripheral)
            bleLogger.debug(error: "Peripheral disconnected. Reason: \(error!)", log: .ble, date: Date()) // MARK: logging
        } else {
            DeviceInfoManager.init().clearDeviceInfo()
            bleLogger.debug(error: "User initiated disconnect", log: .ble, date: Date()) // MARK: logging
        }
        UptimeManager.shared.lastDisconnect = Date()
        UptimeManager.shared.connectTime = nil
        
        ChartManager.shared.addItem(dataPoint: DataPoint(date: Date(), value: 0, chart: ChartsAsInts.connected.rawValue))
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            isSwitchedOn = true
        }
        else {
            isSwitchedOn = false
        }
    }
}
