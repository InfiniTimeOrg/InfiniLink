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

    let fileSystem = MockFileSystem()

    private var timer: Timer?
    private var ticks = 0
    private var heartRate = 72
    private var steps = 0

    private let info: [CBUUID: String] = [
        BLEUUID.modelNumber: "InfiniTime",
        BLEUUID.serial: "0",
        BLEUUID.firmware: MockWatch.firmware,
        BLEUUID.hardwareRevision: "1.0.0",
        BLEUUID.softwareRevision: MockWatch.firmware,
        BLEUUID.manufacturer: "PINE64"
    ]

    func connect() {
        guard Self.isAvailable, !isConnected else { return }

        // Use .shared here instead of storing it, since BLEManager reaches this during its own setup
        let bleManager = BLEManager.shared
        let deviceManager = DeviceManager.shared

        bleManager.stopScanning()
        if deviceManager.pairedDeviceID != Self.id {
            DownloadManager.shared.clearUpdate()
        }
        deviceManager.pairedDeviceID = Self.id
        deviceManager.pairedDevice = deviceManager.currentDevice() ?? deviceManager.addDevice(uuid: Self.id)
        if deviceManager.pairedDevice?.name == nil {
            deviceManager.updateName("Simulator")
        }

        isConnected = true
        bleManager.isConnecting = false
        bleManager.isConnectedToPinetime = true
        bleManager.ancsAuthorized = true
        bleManager.rssi = -55
        bleManager.currentTimeService = characteristic(BLEUUID.time)
        bleManager.blefsTransfer = characteristic(BLEUUID.blefsTransfer)

        for (uuid, value) in info {
            deviceManager.updateInfo(characteristic: characteristic(uuid, value: Data(value.utf8)))
        }
        deviceManager.updateInfo(characteristic: characteristic(BLEUUID.blefsVersion, value: Data([1, 0])))
        deviceManager.readSettingsIfNeeded()

        send(BLEUUID.bat, [UInt8(batteryLevel)])
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.tick()
        }

        log("Connected to simulated watch", type: .info, caller: "MockWatch", target: .ble)
    }

    func disconnect() {
        guard isConnected else { return }

        let bleManager = BLEManager.shared

        timer?.invalidate()
        timer = nil
        isConnected = false
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

    private func tick() {
        ticks += 1
        heartRate = min(max(heartRate + Int.random(in: -3...3), 55), 140)
        steps += Int.random(in: 0...15)

        send(BLEUUID.hrm, [0, UInt8(heartRate)])
        send(BLEUUID.stepCount, withUnsafeBytes(of: UInt32(steps).littleEndian, Array.init))

        let motion = [Int16.random(in: -60...60), Int16.random(in: -60...60), Int16.random(in: -1084 ... -964)]
        send(BLEUUID.motion, motion.flatMap { withUnsafeBytes(of: $0.littleEndian, Array.init) })

        if ticks % 12 == 0 { // drain a percent a minute
            setBatteryLevel(batteryLevel - 1)
        }
    }

    private func send(_ uuid: CBUUID, _ bytes: [UInt8]) {
        BLEManager.shared.lastDataReceivedDate = Date()
        BLECharacteristicHandler.shared.handleUpdates(characteristic: characteristic(uuid, value: Data(bytes)))
    }

    private func characteristic(_ uuid: CBUUID, value: Data? = nil) -> CBMutableCharacteristic {
        let characteristic = CBMutableCharacteristic(type: uuid, properties: [.read, .notify], value: nil, permissions: .readable)
        characteristic.value = value
        return characteristic
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
