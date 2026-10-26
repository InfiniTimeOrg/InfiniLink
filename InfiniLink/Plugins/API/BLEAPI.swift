//
//  BLEAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import CoreBluetooth
import JavaScriptCore

@objc protocol BLEServiceAPIExports: JSExport {
    var uuid: String { get }
    
    func getCharacteristic(_ uuid: String) -> BLECharacteristicAPI?
}

final class BLEServiceAPI: NSObject, BLEServiceAPIExports {
    private weak var runner: PluginRunner?
    private let serviceUUID: CBUUID
    
    init(runner: PluginRunner, uuid: CBUUID) {
        self.runner = runner
        self.serviceUUID = uuid
    }
    
    var uuid: String {
        return serviceUUID.uuidString.lowercased()
    }
    
    func getCharacteristic(_ uuid: String) -> BLECharacteristicAPI? {
        guard let runner else { return nil }
        guard let characteristicUUID = PluginPolicy.uuid(from: uuid) else {
            runner.throwError("Invalid UUID \(uuid)")
            return nil
        }
        guard !PluginPolicy.isBlocked(characteristic: characteristicUUID) else {
            runner.throwError("Plugins can't access characteristic \(uuid)")
            return nil
        }
        
        return BLECharacteristicAPI(runner: runner, serviceUUID: serviceUUID, uuid: characteristicUUID)
    }
}

@objc protocol BLECharacteristicAPIExports: JSExport {
    var uuid: String { get }
    
    func write(_ value: JSValue)
    func read() -> JSValue?
    func readString() -> String?
    func addEventListener(_ event: String, _ callback: JSValue)
    func removeEventListener(_ event: String, _ callback: JSValue)
}

final class BLECharacteristicAPI: NSObject, BLECharacteristicAPIExports {
    private weak var runner: PluginRunner?
    private let serviceUUID: CBUUID
    private let characteristicUUID: CBUUID
    
    init(runner: PluginRunner, serviceUUID: CBUUID, uuid: CBUUID) {
        self.runner = runner
        self.serviceUUID = serviceUUID
        self.characteristicUUID = uuid
    }
    
    var uuid: String {
        return characteristicUUID.uuidString.lowercased()
    }
    
    // CoreBluetooth objects should only be touched on the main queue
    private func characteristic() -> CBCharacteristic? {
        let characteristic = DispatchQueue.main.sync {
            let characteristic = BLEManager.shared.discoveredCharacteristics[characteristicUUID]
            return characteristic?.service?.uuid == serviceUUID ? characteristic : nil
        }
        
        if characteristic == nil {
            runner?.throwError("Characteristic \(uuid) isn't available, is the watch connected?")
        }
        return characteristic
    }
    
    func write(_ value: JSValue) {
        guard let runner else { return }
        guard let data = runner.bytes(from: value) else {
            runner.throwError("write() takes a string, ArrayBuffer, typed array, or array of bytes")
            return
        }
        guard let characteristic = characteristic() else { return }
        
        DispatchQueue.main.async {
            BLEWriteManager().writeRaw(data, to: characteristic)
        }
    }
    
    func read() -> JSValue? {
        guard let runner, let characteristic = characteristic() else { return nil }
        
        let pendingRead = PluginManager.shared.addPendingRead(for: characteristicUUID)
        DispatchQueue.main.async {
            if MockWatch.shared.isConnected {
                MockWatch.shared.read(characteristic.uuid)
            } else {
                BLEManager.shared.infiniTime?.readValue(for: characteristic)
            }
        }
        
        guard pendingRead.semaphore.wait(timeout: .now() + 5) == .success, let data = pendingRead.data else {
            PluginManager.shared.removePendingRead(pendingRead)
            runner.throwError("Timed out reading \(uuid)")
            return nil
        }
        return runner.arrayBuffer(from: data)
    }
    
    func readString() -> String? {
        guard let buffer = read(), let runner, let data = runner.bytes(from: buffer) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
    
    func addEventListener(_ event: String, _ callback: JSValue) {
        guard let runner else { return }
        guard event == "notify" else {
            runner.throwError("Invalid event \(event)")
            return
        }
        guard let characteristic = characteristic() else { return }
        
        runner.notifyListeners[characteristicUUID, default: []].append(callback)
        DispatchQueue.main.async {
            BLEManager.shared.infiniTime?.setNotifyValue(true, for: characteristic)
        }
    }
    
    // Leave notifications on, the app might be using them too
    func removeEventListener(_ event: String, _ callback: JSValue) {
        runner?.notifyListeners[characteristicUUID]?.removeAll { $0.isEqual(to: callback) }
    }
}

final class PendingRead {
    let uuid: CBUUID
    let semaphore = DispatchSemaphore(value: 0)
    var data: Data?
    
    init(uuid: CBUUID) {
        self.uuid = uuid
    }
}
