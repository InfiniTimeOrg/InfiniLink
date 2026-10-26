//
//  PluginStore.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation

enum PluginStore {
    static let directory = URL.applicationSupportDirectory.appending(path: "Plugins")
    
    private static func sourceURL(for id: String) -> URL {
        return directory.appending(path: "\(id).js")
    }
    
    static func source(for id: String) -> String? {
        return try? String(contentsOf: sourceURL(for: id), encoding: .utf8)
    }
    
    static func saveSource(_ source: String, for id: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try source.write(to: sourceURL(for: id), atomically: true, encoding: .utf8)
    }
    
    static func value(of param: PluginParam, for id: String) -> String? {
        if param.kind == .secret {
            return Keychain.get("plugin.\(id).\(param.name)")
        }
        return UserDefaults.standard.dictionary(forKey: "pluginParams.\(id)")?[param.name] as? String
    }
    
    static func setValue(_ value: String?, of param: PluginParam, for id: String) {
        if param.kind == .secret {
            Keychain.set(value, for: "plugin.\(id).\(param.name)")
            return
        }
        
        var values = UserDefaults.standard.dictionary(forKey: "pluginParams.\(id)") ?? [:]
        values[param.name] = value
        UserDefaults.standard.set(values, forKey: "pluginParams.\(id)")
    }
    
    // Stored as JSON strings
    static func storage(for id: String) -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: "pluginStorage.\(id)") as? [String: String] ?? [:]
    }
    
    static func setStorage(_ storage: [String: String], for id: String) {
        UserDefaults.standard.set(storage, forKey: "pluginStorage.\(id)")
    }
    
    static func delete(_ plugin: Plugin) {
        try? FileManager.default.removeItem(at: sourceURL(for: plugin.id))
        UserDefaults.standard.removeObject(forKey: "pluginParams.\(plugin.id)")
        UserDefaults.standard.removeObject(forKey: "pluginStorage.\(plugin.id)")
        
        for param in plugin.params where param.kind == .secret {
            Keychain.set(nil, for: "plugin.\(plugin.id).\(param.name)")
        }
    }
}
