//
//  WatchesAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

@objc protocol WatchesAPIExports: JSExport {
    var all: [WatchAPI] { get }
    
    func addEventListener(_ event: String, _ callback: JSValue)
    func removeEventListener(_ event: String, _ callback: JSValue)
}

final class WatchesAPI: NSObject, WatchesAPIExports {
    private weak var runner: PluginRunner?
    
    init(runner: PluginRunner) {
        self.runner = runner
    }
    
    // InfiniLink only connects to one watch at a time
    var all: [WatchAPI] {
        guard let runner, runner.isWatchReady else { return [] }
        return [WatchAPI(runner: runner)]
    }
    
    func addEventListener(_ event: String, _ callback: JSValue) {
        guard event == "connected" || event == "disconnected" else {
            runner?.throwError("Invalid event \(event)")
            return
        }
        
        runner?.watchListeners[event, default: []].append(callback)
    }
    
    func removeEventListener(_ event: String, _ callback: JSValue) {
        runner?.watchListeners[event]?.removeAll { $0.isEqual(to: callback) }
    }
}

@objc protocol WatchAPIExports: JSExport {
    var isConnected: Bool { get }
    
    func getService(_ uuid: JSValue) -> BLEServiceAPI?
    func sendNotification(_ title: String, _ body: String)
}

final class WatchAPI: NSObject, WatchAPIExports {
    private weak var runner: PluginRunner?
    
    init(runner: PluginRunner) {
        self.runner = runner
    }
    
    var isConnected: Bool {
        return runner?.isWatchReady ?? false
    }
    
    func getService(_ uuid: JSValue) -> BLEServiceAPI? {
        guard let runner else { return nil }
        
        let value = uuid.isNumber ? String(format: "%04X", uuid.toInt32()) : uuid.toString() ?? ""
        guard let serviceUUID = PluginPolicy.uuid(from: value) else {
            runner.throwError("Invalid UUID \(value)")
            return nil
        }
        guard !PluginPolicy.isBlocked(service: serviceUUID) else {
            runner.throwError("Plugins can't access service \(value)")
            return nil
        }
        
        return BLEServiceAPI(runner: runner, uuid: serviceUUID)
    }
    
    func sendNotification(_ title: String, _ body: String) {
        DispatchQueue.main.async {
            BLEWriteManager().sendNotification(AppNotification(title: title, subtitle: body))
        }
    }
}
