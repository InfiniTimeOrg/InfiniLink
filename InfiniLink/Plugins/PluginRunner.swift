//
//  PluginRunner.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import CoreBluetooth
import JavaScriptCore

// Each plugin has its own context and queue so a stuck one can't block anything else
final class PluginRunner {
    let plugin: Plugin
    let queue: DispatchQueue
    
    // Only touched on the queue
    private(set) var context: JSContext?
    private(set) var isWatchReady = false
    var timers: [Int: DispatchSourceTimer] = [:]
    var nextTimerID = 0
    var watchListeners: [String: [JSValue]] = [:]
    var notifyListeners: [CBUUID: [JSValue]] = [:]
    var mediaListeners: [JSValue] = []
    var locationListeners: [JSValue] = []
    private var toBytes: JSValue?
    private var toArrayBuffer: JSValue?
    
    init(plugin: Plugin) {
        self.plugin = plugin
        self.queue = DispatchQueue(label: "Plugin \(plugin.id)")
    }
    
    func start(source: String, watchReady: Bool) {
        queue.async { [self] in
            guard let context = JSContext() else { return }
            
            context.name = plugin.name
            context.exceptionHandler = { [weak self] _, exception in
                guard let exception else { return }
                
                let line = exception.forProperty("line")?.toInt32() ?? 0
                self?.output(.error, "\(exception.toString() ?? "Unknown error") (line \(line))")
            }
            self.context = context
            isWatchReady = watchReady
            
            toBytes = context.evaluateScript("""
            (function (value) {
                if (value instanceof ArrayBuffer) return Array.from(new Uint8Array(value));
                if (ArrayBuffer.isView(value)) return Array.from(new Uint8Array(value.buffer, value.byteOffset, value.byteLength));
                if (Array.isArray(value)) return value;
                return null;
            })
            """)
            toArrayBuffer = context.evaluateScript("(function (bytes) { return new Uint8Array(bytes).buffer; })")
            
            installConsole(in: context)
            installTimers(in: context)
            installParams(in: context)
            installRequire(in: context)
            
            context.evaluateScript(source, withSourceURL: URL(string: "\(plugin.id).js"))
        }
    }
    
    func stop() {
        queue.async { [self] in
            timers.values.forEach { $0.cancel() }
            timers = [:]
            watchListeners = [:]
            notifyListeners = [:]
            mediaListeners = []
            if !locationListeners.isEmpty {
                locationListeners = []
                DispatchQueue.main.async {
                    PluginLocationProvider.shared.setSubscribed(false, for: self)
                }
            }
            toBytes = nil
            toArrayBuffer = nil
            context = nil
        }
    }
    
    func perform(_ block: @escaping (JSContext) -> Void) {
        queue.async { [weak self] in
            guard let context = self?.context else { return }
            block(context)
        }
    }
    
    func watchConnected() {
        perform { [self] _ in
            isWatchReady = true
            
            let watch = WatchAPI(runner: self)
            watchListeners["connected"]?.forEach { $0.call(withArguments: [watch]) }
        }
    }
    
    // Characteristics change between connections, so plugins resubscribe
    func watchDisconnected() {
        perform { [self] _ in
            isWatchReady = false
            notifyListeners = [:]
            
            watchListeners["disconnected"]?.forEach { $0.call(withArguments: []) }
        }
    }
    
    func handleValue(_ data: Data, for uuid: CBUUID) {
        perform { [self] _ in
            guard let listeners = notifyListeners[uuid], let buffer = arrayBuffer(from: data) else { return }
            
            listeners.forEach { $0.call(withArguments: [buffer]) }
        }
    }
    
    func handleMediaChange(_ state: [String: Any]?) {
        perform { [self] _ in
            mediaListeners.forEach { $0.call(withArguments: [state ?? NSNull()]) }
        }
    }
    
    func handleLocation(_ location: [String: Any]) {
        perform { [self] _ in
            locationListeners.forEach { $0.call(withArguments: [location]) }
        }
    }
    
    func output(_ type: DebugLogType, _ message: String) {
        log(message, type: type, caller: plugin.name, target: .plugin)
    }
    
    func throwError(_ message: String) {
        guard let context = JSContext.current() else { return }
        
        context.exception = JSValue(newErrorFromMessage: message, in: context)
    }
    
    func bytes(from value: JSValue) -> Data? {
        if value.isString {
            return Data((value.toString() ?? "").utf8)
        }
        guard let bytes = toBytes?.call(withArguments: [value]), bytes.isArray, let array = bytes.toArray() as? [NSNumber] else { return nil }
        
        return Data(array.map { $0.uint8Value })
    }
    
    func arrayBuffer(from data: Data) -> JSValue? {
        return toArrayBuffer?.call(withArguments: [Array(data)])
    }
    
    private func installParams(in context: JSContext) {
        let values = Dictionary(uniqueKeysWithValues: plugin.params.map { ($0.name, $0.value(from: PluginStore.value(of: $0, for: plugin.id))) })
        
        context.setObject(values, forKeyedSubscript: "params" as NSString)
    }
    
    private func installRequire(in context: JSContext) {
        let require: @convention(block) (String) -> JSValue? = { [weak self] name in
            guard let self, let module = self.module(named: name) else { return nil }
            return JSValue(object: module, in: JSContext.current())
        }
        
        context.setObject(unsafeBitCast(require, to: AnyObject.self), forKeyedSubscript: "require" as NSString)
    }
    
    private func module(named name: String) -> NSObject? {
        switch name {
        case "watches":
            return WatchesAPI(runner: self)
        case "http":
            return hasPermission(.http, for: name) ? HTTPAPI(runner: self) : nil
        case "fs":
            return hasPermission(.filesystem, for: name) ? FSAPI(runner: self) : nil
        case "storage":
            return StorageAPI(runner: self)
        case "volume":
            return hasPermission(.volumeControl, for: name) ? VolumeAPI() : nil
        case "media":
            return hasPermission(.mediaControl, for: name) ? MediaAPI(runner: self) : nil
        case "location":
            return hasPermission(.location, for: name) ? LocationAPI(runner: self) : nil
        default:
            throwError("Unknown module \(name)")
            return nil
        }
    }
    
    private func hasPermission(_ permission: PluginPermission, for module: String) -> Bool {
        guard plugin.permissions.contains(permission) else {
            throwError("The \(module) module needs the \(permission.rawValue) permission")
            return false
        }
        return true
    }
}
