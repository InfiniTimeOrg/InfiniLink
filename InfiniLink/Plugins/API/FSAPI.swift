//
//  FSAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import Foundation
import JavaScriptCore

@objc protocol FSAPIExports: JSExport {
    func read(_ path: String) -> JSValue?
    func readString(_ path: String) -> String?
    func list(_ path: String) -> [[String: Any]]?
    func write(_ path: String, _ data: JSValue) -> Bool
    func mkdir(_ path: String) -> Bool
    func delete(_ path: String) -> Bool
}

// These block until the watch replies, which is fine on the plugin's own queue
final class FSAPI: NSObject, FSAPIExports {
    private weak var runner: PluginRunner?
    private let bleFs = BLEFSHandler.shared
    
    init(runner: PluginRunner) {
        self.runner = runner
    }
    
    private func path(_ path: String, writing: Bool = false) -> String? {
        guard let normalized = PluginPolicy.normalize(path: path) else {
            runner?.throwError("Invalid path \(path)")
            return nil
        }
        guard !writing || PluginPolicy.canWrite(path: normalized) else {
            runner?.throwError("Plugins can't change \(normalized), since /settings.dat, /fonts and /images are managed by InfiniLink")
            return nil
        }
        
        return normalized
    }
    
    func read(_ path: String) -> JSValue? {
        guard let runner, let path = self.path(path) else { return nil }
        
        let file = bleFs.readFile(path: path)
        guard file.valid else {
            if !file.missing {
                runner.throwError("Couldn't read \(path)")
            }
            return nil
        }
        return runner.arrayBuffer(from: file.data)
    }
    
    func readString(_ path: String) -> String? {
        guard let buffer = read(path), let data = runner?.bytes(from: buffer) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
    
    func list(_ path: String) -> [[String: Any]]? {
        guard let path = self.path(path) else { return nil }
        guard let entries = bleFs.listDir(path: path) else {
            runner?.throwError("Couldn't list \(path)")
            return nil
        }
        
        return entries
            .filter { $0.pathNames != "." && $0.pathNames != ".." }
            .map { ["name": $0.pathNames, "isDirectory": $0.isDirectory, "size": $0.fileSize, "modified": $0.modificationTime] }
    }
    
    func write(_ path: String, _ data: JSValue) -> Bool {
        guard let runner, let path = self.path(path, writing: true) else { return false }
        guard let data = runner.bytes(from: data) else {
            runner.throwError("write() takes a string, ArrayBuffer, typed array, or array of bytes")
            return false
        }
        
        return bleFs.writeFile(data: data, path: path)
    }
    
    func mkdir(_ path: String) -> Bool {
        guard let path = self.path(path, writing: true) else { return false }
        return bleFs.makeDir(path: path)
    }
    
    func delete(_ path: String) -> Bool {
        guard let path = self.path(path, writing: true) else { return false }
        return bleFs.deleteFile(path: path)
    }
}
