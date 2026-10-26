//
//  PluginManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import SwiftUI
import CoreBluetooth
import CoreLocation
import MediaPlayer

final class PluginManager: ObservableObject {
    static let shared = PluginManager()
    
    @AppStorage("enablePlugins") var enablePlugins = false
    
    @Published var plugins: [Plugin] {
        didSet {
            save()
        }
    }
    
    private var runners: [String: PluginRunner] = [:]
    private let key = "plugins"
    // Only true once every characteristic is discovered
    private var isWatchReady = false
    // Plugins wait on these from their own queues
    private var pendingReads: [PendingRead] = []
    private let pendingReadsLock = NSLock()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Plugin].self, from: data) {
            plugins = decoded
        } else {
            plugins = []
        }
        
        for name in [NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, .MPMusicPlayerControllerNowPlayingItemDidChange] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.handleMediaChange()
            }
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(plugins) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func reload() {
        for plugin in plugins {
            if enablePlugins && plugin.enabled {
                start(plugin)
            } else {
                stop(plugin.id)
            }
        }
    }
    
    func restart(_ id: String) {
        stop(id)
        reload()
    }
    
    private func start(_ plugin: Plugin) {
        if let runner = runners[plugin.id] {
            guard runner.plugin.checksum != plugin.checksum else { return }
            runner.stop()
        }
        guard let source = PluginStore.source(for: plugin.id) else {
            log("Source for \(plugin.id) is missing", caller: "PluginManager", target: .plugin)
            return
        }
        
        let runner = PluginRunner(plugin: plugin)
        runners[plugin.id] = runner
        runner.start(source: source, watchReady: isWatchReady)
        
        log("Started \(plugin.name)", type: .info, caller: "PluginManager", target: .plugin)
    }
    
    private func stop(_ id: String) {
        guard let runner = runners.removeValue(forKey: id) else { return }
        
        runner.stop()
        log("Stopped \(runner.plugin.name)", type: .info, caller: "PluginManager", target: .plugin)
    }
    
    func install(_ plugin: Plugin, source: String) throws {
        try PluginStore.saveSource(source, for: plugin.id)
        
        var plugin = plugin
        if let index = plugins.firstIndex(where: { $0.id == plugin.id }) {
            plugin.enabled = plugins[index].enabled
            plugins[index] = plugin
        } else {
            plugins.append(plugin)
        }
        reload()
        
        log("Installed \(plugin.name)", type: .info, caller: "PluginManager", target: .plugin)
    }
    
    func setEnabled(_ enabled: Bool, for id: String) {
        guard let index = plugins.firstIndex(where: { $0.id == id }) else { return }
        
        plugins[index].enabled = enabled
        reload()
    }
    
    func delete(_ plugin: Plugin) {
        stop(plugin.id)
        PluginStore.delete(plugin)
        plugins.removeAll { $0.id == plugin.id }
    }
    
    func watchConnected() {
        guard !isWatchReady else { return }
        
        isWatchReady = true
        runners.values.forEach { $0.watchConnected() }
    }
    
    func watchDisconnected() {
        guard isWatchReady else { return }
        
        isWatchReady = false
        runners.values.forEach { $0.watchDisconnected() }
    }
    
    func handleValue(_ characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return }
        
        let reads = pendingReadsLock.withLock {
            let reads = pendingReads.filter { $0.uuid == characteristic.uuid }
            pendingReads.removeAll { $0.uuid == characteristic.uuid }
            return reads
        }
        for read in reads {
            read.data = data
            read.semaphore.signal()
        }
        
        runners.values.forEach { $0.handleValue(data, for: characteristic.uuid) }
    }
    
    func handleMediaChange() {
        let state = MediaAPI.currentState()
        runners.values.forEach { $0.handleMediaChange(state) }
    }
    
    func handleLocation(_ location: CLLocation) {
        let location = LocationAPI.dictionary(from: location)
        runners.values.forEach { $0.handleLocation(location) }
    }
    
    func addPendingRead(for uuid: CBUUID) -> PendingRead {
        let read = PendingRead(uuid: uuid)
        pendingReadsLock.withLock { pendingReads.append(read) }
        return read
    }
    
    func removePendingRead(_ read: PendingRead) {
        pendingReadsLock.withLock { pendingReads.removeAll { $0 === read } }
    }
}
