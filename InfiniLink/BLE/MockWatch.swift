//
//  MockWatch.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/21/26.
//

import Foundation
import CoreBluetooth

// Stands in for a watch on the simulator, where Bluetooth isn't available, by feeding fake values through the real characteristic handlers
class MockWatch: ObservableObject {
    static let shared = MockWatch()
    static let id = "00000000-0000-0000-0000-000000000001"

    #if targetEnvironment(simulator)
    static let isAvailable = true
    #else
    static let isAvailable = false
    #endif

    static let firmware = "1.16.0"

    @Published var isConnected = false
    @Published var batteryLevel = 85
    @Published var isCharging = false
    @Published var lastNotification: String?

    let fileSystem = MockFileSystem()

    private var timer: Timer?
    private var ticks = 0
    private var heartRate = 72
    private var steps = 0
    private var characteristics: [CBUUID: CBMutableCharacteristic] = [:]
    private var gattServices: [CBMutableService] = [] // Characteristics only hold their service weakly

    private let info: [CBUUID: String] = [
        BLEUUID.modelNumber: "InfiniTime",
        BLEUUID.serial: "0",
        BLEUUID.firmware: MockWatch.firmware,
        BLEUUID.hardwareRevision: "1.0.0",
        BLEUUID.softwareRevision: MockWatch.firmware,
        BLEUUID.manufacturer: "PINE64"
    ]

    private let services: [String: [CBUUID]] = [ // So plugins can look up chars by id
        "180D": [BLEUUID.hrm],
        "180F": [BLEUUID.bat, BLEUUID.batteryLevelStatus],
        "1805": [BLEUUID.time],
        "1811": [BLEUUID.notify],
        "180A": [BLEUUID.modelNumber, BLEUUID.serial, BLEUUID.firmware, BLEUUID.hardwareRevision, BLEUUID.softwareRevision, BLEUUID.manufacturer],
        "FEBB": [BLEUUID.blefsVersion, BLEUUID.blefsTransfer],
        "00000000-78FC-48FE-8E23-433B3A1942D0": [BLEUUID.musicControl, BLEUUID.statusControl, BLEUUID.musicArtist, BLEUUID.musicTrack, BLEUUID.positionTrack, BLEUUID.lengthTrack],
        "00010000-78FC-48FE-8E23-433B3A1942D0": [BLEUUID.navigationFlags, BLEUUID.navigationNarrative, BLEUUID.navigationDistance, BLEUUID.navigationProgress],
        "00030000-78FC-48FE-8E23-433B3A1942D0": [BLEUUID.stepCount, BLEUUID.motion],
        "00050000-78FC-48FE-8E23-433B3A1942D0": [BLEUUID.weather]
    ]

    func connect() {
        guard Self.isAvailable, !isConnected else { return }

        let bleManager = BLEManager.shared
        let deviceManager = DeviceManager.shared

        bleManager.stopScanning()
        if deviceManager.pairedDeviceID != Self.id {
            DownloadManager.shared.clearUpdate()
        }
        BLEFSHandler.shared.clearListingCache()
        deviceManager.pairedDeviceID = Self.id
        deviceManager.pairedDevice = deviceManager.currentDevice() ?? deviceManager.addDevice(uuid: Self.id)
        if deviceManager.pairedDevice?.name == nil {
            deviceManager.updateName("Simulator")
        }

        setUpCharacteristics()
        isConnected = true
        bleManager.isConnecting = false
        bleManager.isConnectedToPinetime = true
        bleManager.ancsAuthorized = true
        bleManager.rssi = -55
        bleManager.currentTimeService = characteristics[BLEUUID.time]
        bleManager.blefsTransfer = characteristics[BLEUUID.blefsTransfer]
        bleManager.notifyCharacteristic = characteristics[BLEUUID.notify]
        bleManager.discoveredCharacteristics = characteristics

        var values = info.mapValues { Data($0.utf8) }
        values[BLEUUID.blefsVersion] = Data([1, 0])
        for (uuid, value) in values {
            guard let characteristic = characteristics[uuid] else { continue }

            characteristic.value = value
            deviceManager.updateInfo(characteristic: characteristic)
        }
        deviceManager.readWatchFiles()

        send(BLEUUID.bat, [UInt8(batteryLevel)])
        sendChargeState()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        PluginManager.shared.watchConnected()

        log("Connected to simulated watch", type: .info, caller: "MockWatch", target: .ble)
    }

    func disconnect() {
        guard isConnected else { return }

        let bleManager = BLEManager.shared

        timer?.invalidate()
        timer = nil
        isConnected = false
        characteristics = [:]
        gattServices = []
        bleManager.clearCharacteristics()
        bleManager.isConnectedToPinetime = false
        bleManager.hasLoadedBatteryLevel = false
        bleManager.rssi = nil

        log("Disconnected from simulated watch", type: .info, caller: "MockWatch", target: .ble)
    }

    func setBatteryLevel(_ level: Int) {
        batteryLevel = min(max(level, 0), 100)
        if isConnected {
            send(BLEUUID.bat, [UInt8(batteryLevel)])
        }
    }

    func setCharging(_ charging: Bool) {
        isCharging = charging
        if isConnected {
            sendChargeState()
        }
    }

    private func sendChargeState() {
        let state: UInt16 = !isCharging ? 2 : (batteryLevel == 100 ? 3 : 1)
        let powerState: UInt16 = 1 | (isCharging ? 0b10 : 0) | (state << 5)
        send(BLEUUID.batteryLevelStatus, [0, UInt8(powerState & 0xFF), UInt8(powerState >> 8)])
    }

    func read(_ uuid: CBUUID) {
        guard let characteristic = characteristics[uuid] else { return }

        PluginManager.shared.handleValue(characteristic)
    }

    func write(_ data: Data, to uuid: CBUUID) {
        guard let characteristic = characteristics[uuid] else { return }

        characteristic.value = data
        if uuid == BLEUUID.notify {
            // Three header bytes, then the title and body, each ending in a null
            let parts = data.dropFirst(3).split(separator: 0, omittingEmptySubsequences: false).map { String(decoding: $0, as: UTF8.self) }
            lastNotification = parts.prefix(2).filter { !$0.isEmpty }.joined(separator: ": ")
            log("Simulated watch got notification: \(lastNotification ?? "")", type: .info, caller: "MockWatch", target: .ble)
        } else {
            log("Simulated watch got \(data.count) bytes on \(uuid)", type: .info, caller: "MockWatch", target: .ble)
        }
    }

    private func tick() {
        ticks += 1
        heartRate = min(max(heartRate + Int.random(in: -3...3), 55), 140)
        steps += Int.random(in: 0...15)

        send(BLEUUID.hrm, [0, UInt8(heartRate)])
        send(BLEUUID.stepCount, withUnsafeBytes(of: UInt32(steps).littleEndian, Array.init))

        let motion = [Int16.random(in: -60...60), Int16.random(in: -60...60), Int16.random(in: -1084 ... -964)]
        send(BLEUUID.motion, motion.flatMap { withUnsafeBytes(of: $0.littleEndian, Array.init) })

        if isCharging {
            setBatteryLevel(batteryLevel + 1)
            sendChargeState()
        } else if ticks % 12 == 0 { // drain a percent a minute
            setBatteryLevel(batteryLevel - 1)
        }
    }

    private func send(_ uuid: CBUUID, _ bytes: [UInt8]) {
        guard let characteristic = characteristics[uuid] else { return }

        characteristic.value = Data(bytes)
        BLEManager.shared.lastDataReceivedDate = Date()
        BLECharacteristicHandler.shared.handleUpdates(characteristic: characteristic)
        PluginManager.shared.handleValue(characteristic)
    }

    private func setUpCharacteristics() {
        gattServices = services.map { serviceUUID, uuids in
            let service = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)
            service.characteristics = uuids.map { uuid in
                let characteristic = CBMutableCharacteristic(type: uuid, properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
                characteristic.value = Data()
                characteristics[uuid] = characteristic
                return characteristic
            }
            return service
        }
    }
}

// The simulator doesn't have Apple Music
class MockMusicPlayer: ObservableObject, PluginMusicPlayer {
    static let shared = MockMusicPlayer()

    private let songs = [
        (title: "Bluetooth Low Energy", artist: "The Pinetimes", album: "InfiniTime", duration: 214.0),
        (title: "Over the Air", artist: "The Pinetimes", album: "InfiniTime", duration: 187.0),
        (title: "Heart Rate", artist: "Sensor", album: "Wrist", duration: 241.0)
    ]

    @Published private(set) var index = 0
    @Published private(set) var isPlaying = false
    @Published var volume = 8 // Out of 15
    private var elapsed: TimeInterval = 0
    private var resumedDate: Date?

    var title: String {
        return songs[index].title
    }

    var currentPlaybackTime: TimeInterval {
        get {
            return min(elapsed + (resumedDate.map { Date().timeIntervalSince($0) } ?? 0), songs[index].duration)
        }
        set {
            elapsed = min(max(newValue, 0), songs[index].duration)
            resumedDate = isPlaying ? Date() : nil
            changed()
        }
    }

    var state: [String: Any] {
        let song = songs[index]
        return [
            "isPlaying": isPlaying,
            "position": Int(currentPlaybackTime),
            "duration": Int(song.duration),
            "title": song.title,
            "artist": song.artist,
            "album": song.album
        ]
    }

    func play() {
        guard !isPlaying else { return }

        isPlaying = true
        resumedDate = Date()
        changed()
    }

    func pause() {
        guard isPlaying else { return }

        elapsed = currentPlaybackTime
        isPlaying = false
        resumedDate = nil
        changed()
    }

    func skipToNextItem() {
        index = (index + 1) % songs.count
        currentPlaybackTime = 0
    }

    func skipToPreviousItem() {
        index = (index + songs.count - 1) % songs.count
        currentPlaybackTime = 0
    }

    func beginGeneratingPlaybackNotifications() {}

    private func changed() {
        PluginManager.shared.handleMediaChange()
    }
}

// Answers BLE FS packets the way the watch does, using a folder on disk so files survive relaunches
class MockFileSystem {
    typealias Commands = BLEFSHandler.Commands
    typealias Responses = BLEFSHandler.Responses

    private let fileManager = FileManager.default
    private let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("MockWatch")

    private var reading: URL?
    private var writing: (url: URL, data: Data)?

    init() {
        guard !fileManager.fileExists(atPath: root.path) else { return }

        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        if let version = WatchSettingsFile.expectedVersion(forFirmware: MockWatch.firmware), let settings = WatchSettingsFile.defaults(version: version) {
            try? settings.data.write(to: url("/settings.dat"))
        }
    }

    func respond(to packet: [UInt8]) -> [[UInt8]] {
        guard packet.count >= 4, let command = Commands(rawValue: packet[0]) else { return [] }

        switch command {
        case .readInit:
            guard packet.count >= 12 else { return [status(.readResponse, .protocolError)] }
            reading = url(path(packet, at: 12))
            return [read(offset: packet.littleEndianValue(at: 4), chunkSize: packet.littleEndianValue(at: 8))]
        case .readData:
            guard packet.count >= 12 else { return [status(.readResponse, .protocolError)] }
            return [read(offset: packet.littleEndianValue(at: 4), chunkSize: packet.littleEndianValue(at: 8))]
        case .write:
            guard packet.count >= 20 else { return [status(.writeResponse, .protocolError)] }
            let url = url(path(packet, at: 20))
            guard isDirectory(url.deletingLastPathComponent()), !isDirectory(url) else { return [writeResponse(.error, offset: 0)] }

            let size: UInt32 = packet.littleEndianValue(at: 16)
            writing = (url, Data(count: Int(size)))
            if size == 0 {
                finishWrite()
            }
            return [writeResponse(.ok, offset: 0)]
        case .writeData:
            guard packet.count >= 12, var writing else { return [writeResponse(.protocolError, offset: 0)] }
            let offset = Int(packet.littleEndianValue(at: 4) as UInt32)
            let chunk = packet.dropFirst(12)
            guard offset + chunk.count <= writing.data.count else { return [writeResponse(.protocolError, offset: UInt32(offset))] }

            writing.data.replaceSubrange(offset..<offset + chunk.count, with: chunk)
            self.writing = writing
            if offset + chunk.count == writing.data.count {
                finishWrite()
            }
            return [writeResponse(.ok, offset: UInt32(offset + chunk.count))]
        case .delete:
            let url = url(path(packet, at: 4))
            guard url != root, fileManager.fileExists(atPath: url.path) else { return [status(.deleteResponse, .noFile)] }
            if isDirectory(url) && !((try? fileManager.contentsOfDirectory(atPath: url.path))?.isEmpty ?? true) {
                return [status(.deleteResponse, .dirNotEmptyError)]
            }
            return [status(.deleteResponse, (try? fileManager.removeItem(at: url)) == nil ? .error : .ok)]
        case .mkdir:
            guard packet.count >= 16 else { return [status(.mkdirResponse, .protocolError)] }
            let url = url(path(packet, at: 16))
            guard !fileManager.fileExists(atPath: url.path) else { return [status(.mkdirResponse, .error)] }
            guard isDirectory(url.deletingLastPathComponent()) else { return [status(.mkdirResponse, .noFile)] }
            return [status(.mkdirResponse, (try? fileManager.createDirectory(at: url, withIntermediateDirectories: false)) == nil ? .error : .ok)]
        case .ls:
            let url = url(path(packet, at: 4))
            guard isDirectory(url), let names = try? fileManager.contentsOfDirectory(atPath: url.path) else { return [status(.lsResponse, .noFile)] }

            // The watch lists . and .. too, then ends with an entry numbered the total
            let entries = [".", ".."] + names.sorted()
            let total = UInt32(entries.count)
            return entries.enumerated().map { index, name in
                listEntry(name, in: url, number: UInt32(index), total: total)
            } + [listEntry(nil, in: url, number: total, total: total)]
        default:
            return []
        }
    }

    private func read(offset: UInt32, chunkSize: UInt32) -> [UInt8] {
        guard let reading, !isDirectory(reading), let data = fileManager.contents(atPath: reading.path) else {
            return status(.readResponse, .noFile)
        }

        let start = min(Int(offset), data.count)
        let chunk = data[start..<min(start + Int(chunkSize), data.count)]

        var response: [UInt8] = [Commands.readResponse.rawValue, Responses.ok.rawValue, 0, 0]
        response += offset.littleEndianBytes
        response += UInt32(data.count).littleEndianBytes
        response += UInt32(chunk.count).littleEndianBytes
        response += chunk
        return response
    }

    private func finishWrite() {
        guard let writing else { return }

        try? writing.data.write(to: writing.url)
        self.writing = nil
    }

    private func writeResponse(_ result: Responses, offset: UInt32) -> [UInt8] {
        var response: [UInt8] = [Commands.writeResponse.rawValue, result.rawValue, 0, 0]
        response += offset.littleEndianBytes
        response += UInt64(Date().timeIntervalSince1970 * 1_000_000_000).littleEndianBytes
        response += UInt32(1_000_000).littleEndianBytes // Free space
        return response
    }

    private func listEntry(_ name: String?, in directory: URL, number: UInt32, total: UInt32) -> [UInt8] {
        let url = directory.appendingPathComponent(name ?? "")
        let attributes = name == nil ? nil : try? fileManager.attributesOfItem(atPath: url.path)
        let isDirectory = name == "." || name == ".." || (name != nil && isDirectory(url))
        let modified = (attributes?[.modificationDate] as? Date) ?? Date()
        let nameBytes = Array((name ?? "").utf8)

        var response: [UInt8] = [Commands.lsResponse.rawValue, Responses.ok.rawValue]
        response += UInt16(nameBytes.count).littleEndianBytes
        response += number.littleEndianBytes
        response += total.littleEndianBytes
        response += UInt32(isDirectory ? 1 : 0).littleEndianBytes
        response += UInt64(modified.timeIntervalSince1970 * 1_000_000_000).littleEndianBytes
        response += UInt32((attributes?[.size] as? Int) ?? 0).littleEndianBytes
        response += nameBytes
        return response
    }

    private func status(_ command: Commands, _ result: Responses) -> [UInt8] {
        [command.rawValue, result.rawValue]
    }

    // Requests put the path's length at byte 2 and the path after their fixed fields
    private func path(_ packet: [UInt8], at offset: Int) -> String {
        let length = Int(packet.littleEndianValue(at: 2) as UInt16)
        return String(decoding: packet.dropFirst(offset).prefix(length), as: UTF8.self)
    }

    private func url(_ path: String) -> URL {
        let components = path.split(separator: "/").filter { $0 != "." && $0 != ".." }
        return components.reduce(root) { $0.appendingPathComponent(String($1)) }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
