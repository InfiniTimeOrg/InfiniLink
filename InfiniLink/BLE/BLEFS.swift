//
//  BLE_FS.swift
//  InfiniLink
//
//  Created by Alex Emry on 1/7/22.
//
//

import CoreBluetooth
import Zip
import SwiftUI

class BLEFSHandler: ObservableObject {
    static let shared = BLEFSHandler()
    
    let bleManager = BLEManager.shared
    let dfuUpdater = DFUUpdater.shared
    
    struct ReadFileFS {
        var data = Data()
        var valid = false
        var missing = false
    }
    
    struct Dir {
        var modificationTime: Int = 0
        var fileSize: Int = 0
        var flags: Int = 0
        var pathNames: String = ""
        
        var isDirectory: Bool { flags & 1 == 1 }
    }
    
    enum Commands : UInt8 {
        case padding = 0x00
        
        // Commands
        case readInit = 0x10
        case readResponse = 0x11
        case readData = 0x12
        
        case write = 0x20
        case writeResponse = 0x21
        case writeData = 0x22
        
        case delete = 0x30
        case deleteResponse = 0x31
        
        case mkdir = 0x40
        case mkdirResponse = 0x41
        
        case ls = 0x50
        case lsResponse = 0x51
    }

    enum Responses: UInt8 {

        // Status/responses
        case ok = 0x01
        case error = 0x02
        case noFile = 0x03
        case protocolError = 0x04
        case readOnly = 0x05
        
        // Extended status
        case dirNotEmptyError = 0x0A
        
        var description: String {
            switch self {
            case .ok: return "OK"
            case .error: return "error"
            case .noFile: return "no file"
            case .protocolError: return "protocol error"
            case .readOnly: return "read only"
            case .dirNotEmptyError: return "directory not empty"
            }
        }
    }
    
    @Published var progress: Int = 0
    
    private let responseTimeout = DispatchTimeInterval.seconds(5)
    private let maxReadChunkSize: UInt32 = 490
    private let writeChunkSize = 170
    
    // Responses arrive on the main queue while requests wait for them on a background one
    private let responseLock = NSLock()
    private let responseSignal = DispatchSemaphore(value: 0)
    private var responses: [[UInt8]] = []
    // The watch handles one request at a time
    private let requestLock = NSLock()
    
    func uploadExternalResources(from url: URL, completion: @escaping() -> Void) {
        log("External resource upload requested", type: .info, caller: "BLEFSHandler", target: .ble)
        
        DispatchQueue.global(qos: .default).async { [self] in
            do {
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
                
                let unzipDirectory = try Zip.quickUnzipFile(url)
                let jsonData = try Data(contentsOf: unzipDirectory.appendingPathComponent("resources.json"))
                let resources = try JSONDecoder().decode(ResourcesJSON.self, from: jsonData).resources
                
                for (index, resource) in resources.enumerated() {
                    createDir(path: resource.path)
                    let fileData = try Data(contentsOf: unzipDirectory.appendingPathComponent(resource.filename))
                    
                    DispatchQueue.main.async {
                        self.dfuUpdater.statusDetail = "Uploading file \(index + 1) of \(resources.count)"
                    }
                    
                    guard writeFile(data: fileData, path: resource.path) else {
                        DispatchQueue.main.async { self.dfuUpdater.reportResourceUploadFailure() }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    self.dfuUpdater.statusDetail = "Completing uploads"
                    
                    completion()
                }
            } catch {
                log("Error parsing resources", caller: "BLEFSHandler", target: .ble)
                
                DispatchQueue.main.async {
                    self.dfuUpdater.reportResourceUploadFailure()
                }
            }
        }
    }
    
    // Make each parent directory of the path, ignoring ones that already exist
    private func createDir(path: String) {
        let components = path.split(separator: "/").dropLast()
        
        for index in components.indices {
            _ = makeDir(path: "/" + components[...index].joined(separator: "/"))
        }
    }
    
    func handleResponse(responseData: [UInt8]) {
        responseLock.withLock { responses.append(responseData) }
        responseSignal.signal()
    }
    
    private func nextResponse(_ command: Commands) -> [UInt8]? {
        while responseSignal.wait(timeout: .now() + responseTimeout) == .success {
            let response = responseLock.withLock { responses.removeFirst() }
            if response.count >= 2 && response[0] == command.rawValue {
                return response
            }
        }
        
        log("Timed out waiting for a BLE FS response", caller: "BLEFSHandler", target: .ble)
        return nil
    }
    
    private func send(_ packet: Data, expecting command: Commands) -> [UInt8]? {
        // Responses arrive on the main queue, so waiting for them there would always time out
        assert(!Thread.isMainThread, "BLE FS requests must run off the main thread")
        guard bleManager.isConnectedToPinetime, let transfer = bleManager.blefsTransfer else { return nil }
        
        // Drop anything left over from a request that timed out
        while responseSignal.wait(timeout: .now()) == .success {
            _ = responseLock.withLock { responses.removeFirst() }
        }
        
        if MockWatch.shared.isConnected {
            MockWatch.shared.fileSystem.respond(to: [UInt8](packet)).forEach(handleResponse)
        } else {
            guard let infiniTime = bleManager.infiniTime else { return nil }
            infiniTime.writeValue(packet, for: transfer, type: .withResponse)
        }
        return nextResponse(command)
    }
    
    private func isOK(_ response: [UInt8]?, _ request: String, logFailure: Bool = true) -> Bool {
        guard let response else { return false }
        guard response[1] == Responses.ok.rawValue else {
            if logFailure {
                log("\(request) failed: \(Responses(rawValue: response[1])?.description ?? "unknown response \(response[1])")", caller: "BLEFSHandler", target: .ble)
            }
            return false
        }
        
        return true
    }
    
    // Command, padding, then the path's length in bytes
    private func header(_ command: Commands, path: String) -> Data {
        var data = Data([command.rawValue, Commands.padding.rawValue])
        data.append(contentsOf: UInt16(path.utf8.count).littleEndianBytes)
        return data
    }
    
    func readFile(path: String) -> ReadFileFS {
        log("Read file called", type: .info, caller: "BLEFSHandler", target: .ble)
        
        return requestLock.withLock {
            var result = ReadFileFS()
            
            var packet = header(.readInit, path: path)
            packet.append(contentsOf: UInt32(0).littleEndianBytes)
            packet.append(contentsOf: maxReadChunkSize.littleEndianBytes)
            packet.append(Data(path.utf8))
            
            while let response = send(packet, expecting: .readResponse) {
                guard isOK(response, "Read \(path)", logFailure: response[1] != Responses.noFile.rawValue), response.count >= 16 else {
                    result.missing = response[1] == Responses.noFile.rawValue
                    return result
                }
                
                let chunkOffset: UInt32 = response.littleEndianValue(at: 4)
                let totalLength: UInt32 = response.littleEndianValue(at: 8)
                let chunkLength: UInt32 = response.littleEndianValue(at: 12)
                result.data.append(contentsOf: response.dropFirst(16))
                
                let nextOffset = chunkOffset + chunkLength
                if nextOffset >= totalLength {
                    result.valid = true
                    return result
                }
                guard chunkLength > 0 else { return result }
                
                packet = Data([Commands.readData.rawValue, Responses.ok.rawValue, Commands.padding.rawValue, Commands.padding.rawValue])
                packet.append(contentsOf: nextOffset.littleEndianBytes)
                packet.append(contentsOf: maxReadChunkSize.littleEndianBytes)
            }
            
            return result
        }
    }

    func writeFile(data: Data, path: String) -> Bool {
        log("Write file called", type: .info, caller: "BLEFSHandler", target: .ble)
        
        return requestLock.withLock {
            var packet = header(.write, path: path)
            packet.append(contentsOf: UInt32(0).littleEndianBytes)
            packet.append(contentsOf: UInt64(Date().timeIntervalSince1970).littleEndianBytes)
            packet.append(contentsOf: UInt32(data.count).littleEndianBytes)
            packet.append(Data(path.utf8))
            
            guard isOK(send(packet, expecting: .writeResponse), "Write \(path)") else { return false }
            
            DispatchQueue.main.async { self.progress = 0 }
            
            var sent = 0
            while sent < data.count {
                let end = min(sent + writeChunkSize, data.count)
                
                packet = Data([Commands.writeData.rawValue, Responses.ok.rawValue, Commands.padding.rawValue, Commands.padding.rawValue])
                packet.append(contentsOf: UInt32(sent).littleEndianBytes)
                packet.append(contentsOf: UInt32(end - sent).littleEndianBytes)
                packet.append(data.subdata(in: sent..<end))
                
                // Wait for the watch to acknowledge this chunk before sending the next one
                guard isOK(send(packet, expecting: .writeResponse), "Write \(path)") else { return false }
                
                sent = end
                DispatchQueue.main.async { self.progress = end }
            }
            
            return true
        }
    }
    
    func deleteFile(path: String) -> Bool {
        log("Delete file called", type: .info, caller: "BLEFSHandler", target: .ble)
        
        return requestLock.withLock {
            var packet = header(.delete, path: path)
            packet.append(Data(path.utf8))
            
            return isOK(send(packet, expecting: .deleteResponse), "Delete \(path)")
        }
    }
    
    // Fails if the directory already exists, so callers that don't care can ignore the result
    func makeDir(path: String) -> Bool {
        log("Make directory called", type: .info, caller: "BLEFSHandler", target: .ble)
        
        return requestLock.withLock {
            var packet = header(.mkdir, path: path)
            packet.append(contentsOf: [UInt8](repeating: 0, count: 4))
            packet.append(contentsOf: UInt64(Date().timeIntervalSince1970).littleEndianBytes)
            packet.append(Data(path.utf8))
            
            return isOK(send(packet, expecting: .mkdirResponse), "Make directory \(path)", logFailure: false)
        }
    }

    func listDir(path: String) -> [Dir]? {
        log("List directory called", type: .info, caller: "BLEFSHandler", target: .ble)
        
        return requestLock.withLock {
            var packet = header(.ls, path: path)
            packet.append(Data(path.utf8))
            
            var entries: [Dir] = []
            var response = send(packet, expecting: .lsResponse)
            
            // The watch sends one response per entry, then one with the entry number equal to the total
            while let entry = response {
                guard isOK(entry, "List \(path)"), entry.count >= 12 else { return nil }
                
                let entryNumber: UInt32 = entry.littleEndianValue(at: 4)
                let totalEntries: UInt32 = entry.littleEndianValue(at: 8)
                if entryNumber >= totalEntries {
                    return entries
                }
                guard entry.count >= 28 else { return nil }
                
                let pathLength: UInt16 = entry.littleEndianValue(at: 2)
                let modificationTime: UInt64 = entry.littleEndianValue(at: 16)
                let fileSize: UInt32 = entry.littleEndianValue(at: 24)
                let flags: UInt32 = entry.littleEndianValue(at: 12)
                entries.append(Dir(modificationTime: Int(truncatingIfNeeded: modificationTime), fileSize: Int(fileSize), flags: Int(flags), pathNames: String(decoding: entry.dropFirst(28).prefix(Int(pathLength)), as: UTF8.self)))
                
                response = nextResponse(.lsResponse)
            }
            
            return nil
        }
    }
    
    func readFile(_ filePath: String, completion: @escaping(Data) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let data = self.readFile(path: filePath).data
            
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    func readSettings(completion: @escaping(Settings?) -> Void) {
        log("Settings requested", type: .info, caller: "BLEFSHandler", target: .ble)
        
        DispatchQueue.global(qos: .default).async {
            let readFile = self.readFile(path: "/settings.dat")
            
            guard let file = WatchSettingsFile(data: readFile.data) else {
                log("Settings file not readable: \(readFile.data.count) bytes, version \(WatchSettingsFile.version(of: readFile.data).map { String(format: "0x%02x", $0) } ?? "none")", caller: "BLEFSHandler", target: .ble)
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            DispatchQueue.main.async {
                DeviceManager.shared.updateHeartRateBackgroundPeriod(from: file)
                completion(file.settings)
            }
        }
    }
    
    func readSettingsFile(completion: @escaping(WatchSettingsFile?, Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let readFile = self.readFile(path: "/settings.dat")
            let firmware = DeviceManager.shared.firmware
            let expected = WatchSettingsFile.expectedVersion(forFirmware: firmware)
            let fileVersion = WatchSettingsFile.version(of: readFile.data)

            var file = WatchSettingsFile(data: readFile.data)
            var usingDefaults = false
            var detail: String?

            // The watch only loads settings.dat if the version matches, so if it's missing or from older firmware it's on defaults. Anything else we leave alone
            let isOlder = readFile.valid && fileVersion.map { $0 < (expected ?? 0) } ?? false
            if let expected, readFile.missing || isOlder {
                file = WatchSettingsFile.defaults(version: expected)
                usingDefaults = file != nil
            } else if let expected, file?.version != expected {
                file = nil
            }

            if file == nil {
                detail = readFile.valid || readFile.missing ? nil : "read failed, "
                detail = (detail ?? "") + "firmware \(firmware), file version \(fileVersion.map { String(format: "0x%02x", $0) } ?? "none"), \(readFile.data.count) bytes"
            }
            if file == nil || usingDefaults {
                log("Settings file not used as is: firmware \(firmware), file version \(fileVersion.map { String(format: "0x%02x", $0) } ?? "none"), \(readFile.data.count) bytes", caller: "BLEFSHandler", target: .ble)
            }
            if let file {
                DeviceManager.shared.updateHeartRateBackgroundPeriod(from: file)
            }

            DispatchQueue.main.async {
                if let file {
                    DeviceManager.shared.updateSettings(file.settings)
                }
                completion(file, usingDefaults, detail)
            }
        }
    }

    func writeSettingsFile(_ file: WatchSettingsFile, completion: @escaping(Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.writeFile(data: file.data, path: "/settings.dat")

            DispatchQueue.main.async {
                if success {
                    DeviceManager.shared.updateSettings(file.settings)
                    DeviceManager.shared.updateHeartRateBackgroundPeriod(from: file)
                }
                completion(success)
            }
        }
    }

    func readAlarmFile(completion: @escaping(WatchAlarmFile?, Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let readFile = self.readFile(path: WatchAlarmFile.path)
            let version = readFile.data.first

            var file = WatchAlarmFile(data: readFile.data)
            var usingDefaults = false
            var detail: String?

            if file == nil && (readFile.missing || (readFile.valid && (version ?? 0) < WatchAlarmFile.currentVersion)) {
                file = WatchAlarmFile.defaults
                usingDefaults = true
            } else if file == nil {
                detail = "\(readFile.valid ? "" : "read failed, ")alarm version \(version.map { String($0) } ?? "none"), \(readFile.data.count) bytes"
                log("Alarm file not usable: \(detail ?? "")", caller: "BLEFSHandler", target: .ble)
            }

            DispatchQueue.main.async {
                completion(file, usingDefaults, detail)
            }
        }
    }

    func writeAlarmFile(_ file: WatchAlarmFile, completion: @escaping(Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // /.system might not exist yet. If it does this just errors and we keep going
            _ = self.makeDir(path: WatchAlarmFile.directory)
            let success = self.writeFile(data: file.data, path: WatchAlarmFile.path)

            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}

struct ResourceFile: Codable {
    let filename: String
    let path: String
}

struct ResourcesJSON: Codable {
    let resources: [ResourceFile]
}

enum ClockType: UInt8 {
    case H24 = 0
    case H12 = 1
}

enum WeatherFormat: UInt8 {
    case Metric = 0
    case Imperial = 1
}

enum Notification: UInt8 {
    case On = 0
    case Off = 1
    case Sleep = 2
}

enum ChimesOption: UInt8 {
    case None = 0
    case Hours = 1
    case HalfHours = 2
}

enum WakeUpMode: UInt8 {
    case SingleTap = 0
    case DoubleTap = 1
    case RaiseWrist = 2
    case Shake = 3
    case LowerWrist = 4
}

enum BrightLevel: UInt8 {
    case Low = 0
    case Mid = 1
    case High = 2
}

enum Colors: UInt8 {
    case White = 0
    case Silver = 1
    case Gray = 2
    case Black = 3
    case Red = 4
    case Maroon = 5
    case Yellow = 6
    case Olive = 7
    case Lime = 8
    case Green = 9
    case Cyan = 10
    case Teal = 11
    case Blue = 12
    case Navy = 13
    case Magenta = 14
    case Purple = 15
    case Orange = 16
    case Pink = 17
}

enum PTSGaugeStyle: UInt8 {
    case Full = 0
    case Half = 1
    case Numeric = 2
}

enum PTSWeather: UInt8 {
    case On = 0
    case Off = 1
}

struct PineTimeStyleData {
    var ColorTime: Colors = .Teal
    var ColorBar: Colors = .Teal
    var ColorBG: Colors = .Black
    var gaugeStyle: PTSGaugeStyle = .Full
    var weatherEnable: PTSWeather = .Off
}

struct WatchFaceInfineat {
    var showSideCover: Bool = true
    var colorIndex: UInt8 = 0
}

struct Settings {
    var version: UInt32 = 4
    var stepsGoal: UInt32 = 10000
    var screenTimeOut: UInt32 = 15000
    var alwaysOnDisplay: Bool = false
    var clockType: ClockType = .H24
    var weatherFormat: WeatherFormat = .Metric
    var notificationStatus: Notification = .On
    var watchFace: UInt8 = 0
    var chimesOption: ChimesOption = .None
    var pineTimeStyle: PineTimeStyleData = PineTimeStyleData()
    var watchFaceInfineat: WatchFaceInfineat = WatchFaceInfineat()
    var wakeUpMode: WakeUpMode = .RaiseWrist
    var shakeWakeThreshold: UInt16 = 150
    var brightLevel: BrightLevel = .Mid
    var prideFlag: UInt8 = 0
}
