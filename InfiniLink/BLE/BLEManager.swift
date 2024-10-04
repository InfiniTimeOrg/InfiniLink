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
    
    var myCentral: CBCentralManager!
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
        let weather =       CBUUID(string: "00050001-78FC-48FE-8E23-433B3A1942D0")
        let musicControl =  CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")
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
    @Published var isConnectedToPinetime = false
    @Published var setTimeError = false
    
    @Published var newPeripherals: [CBPeripheral] = []
    @Published var infiniTime: CBPeripheral!
    
    @Published var watchFace: Int = -1
    @Published var pineTimeStyleData: PineTimeStyleData?
    @Published var infineatWatchFace: WatchFaceInfineat?
    @Published var timeFormat: ClockType?
    
    @Published var weatherInformation = WeatherInformation()
    @Published var weatherForecastDays = [WeatherForecastDay]()
    @Published var loadingWeather = true
    
    @Published var heartRate: Double = 0
    @Published var batteryLevel: Double = 0
    @Published var stepCount: Int = 0
    @Published var firmwareVersion: String = ""
    
    @Published var lastWeatherUpdateNWS: Int = 0
    @Published var lastWeatherUpdateWAPI: Int = 0
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    
    @AppStorage("pairedDeviceID") var pairedDeviceID: String?
    @AppStorage("weatherMode") var weatherMode: String = "imperial"
    
    var hasLoadedCharacteristics: Bool {
        return !DeviceInfoManager.shared.firmware.isEmpty
    }
    
    override init() {
        super.init()
        myCentral = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard myCentral.state == .poweredOn else { return }
        
        myCentral.scanForPeripherals(withServices: nil, options: nil)
        isScanning = true
        newPeripherals = []
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        myCentral.stopScan()
        isScanning = false
    }
    
    func connect(peripheral: CBPeripheral) {
        guard isSwitchedOn else { return }
        
        if peripheral.name == "InfiniTime" {
            if isConnectedToPinetime {
                disconnect()
            }
            myCentral.stopScan()
            isScanning = false
            
            infiniTime = peripheral
            infiniTime?.delegate = self
            myCentral.connect(peripheral, options: nil)
        }
    }
    
    func disconnect() {
        if let infiniTime = infiniTime {
            myCentral.cancelPeripheralConnection(infiniTime)
            isConnectedToPinetime = false
            self.infiniTime = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pairedDeviceID = pairedDeviceID, pairedDeviceID == peripheral.identifier.uuidString {
            connect(peripheral: peripheral)
        }
        if peripheral.name == "InfiniTime" && !newPeripherals.contains(where: { $0.identifier.uuidString == peripheral.identifier.uuidString }) {
            newPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Failed to connect to peripheral: \(error.localizedDescription)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.infiniTime.discoverServices(nil)
        self.pairedDeviceID = peripheral.identifier.uuidString
        DeviceInfoManager.shared.setDeviceName(uuid: peripheral.identifier.uuidString)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
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
            peripheral.discoverCharacteristics(nil, for:service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            DeviceInfoManager.shared.readInfoCharacteristics(characteristic: characteristic, peripheral: peripheral)
            BLEDiscoveredCharacteristics().handleDiscoveredCharacteristics(characteristic: characteristic, peripheral: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        DeviceInfoManager.shared.updateInfo(characteristic: characteristic)
        BLEUpdatedCharacteristicHandler().handleUpdates(characteristic: characteristic, peripheral: peripheral)
    }
}
