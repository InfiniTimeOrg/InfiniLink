//
//  StorageAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

@objc protocol StorageAPIExports: JSExport {
    func get(_ key: String) -> JSValue?
    func set(_ key: String, _ value: JSValue)
    func remove(_ key: String)
    func keys() -> [String]
    func clear()
}

final class StorageAPI: NSObject, StorageAPIExports {
    private weak var runner: PluginRunner?
    private let id: String
    private let limit = 512 * 1024
    
    init(runner: PluginRunner) {
        self.runner = runner
        self.id = runner.plugin.id
    }
    
    private func json(_ method: String, _ value: Any) -> JSValue? {
        return JSContext.current()?.objectForKeyedSubscript("JSON")?.invokeMethod(method, withArguments: [value])
    }
    
    func get(_ key: String) -> JSValue? {
        guard let value = PluginStore.storage(for: id)[key] else { return nil }
        return json("parse", value)
    }
    
    func set(_ key: String, _ value: JSValue) {
        guard let string = json("stringify", value), string.isString, let encoded = string.toString() else {
            remove(key)
            return
        }
        
        var storage = PluginStore.storage(for: id)
        storage[key] = encoded
        guard storage.reduce(0, { $0 + $1.key.utf8.count + $1.value.utf8.count }) <= limit else {
            runner?.throwError("Storage is limited to 512 KB per plugin")
            return
        }
        PluginStore.setStorage(storage, for: id)
    }
    
    func remove(_ key: String) {
        var storage = PluginStore.storage(for: id)
        storage[key] = nil
        PluginStore.setStorage(storage, for: id)
    }
    
    func keys() -> [String] {
        return PluginStore.storage(for: id).keys.sorted()
    }
    
    func clear() {
        PluginStore.setStorage([:], for: id)
    }
}
