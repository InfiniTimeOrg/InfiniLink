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
    static var shared = BLEFSHandler()
    
    let bleManager = BLEManager.shared
    let dfuUpdater = DFUUpdater.shared
    
    var informationTransfer: [InformationFS] = []
    var readFileFS: ReadFileFS = ReadFileFS()
    var writeFileFS: WriteFileFS = WriteFileFS()
    
    struct WriteFileFS {
        var group = DispatchGroup()
        var offset: Int = 0
        var freeSpace: UInt32  = 0
        var data = Data()
        var completed: Bool = false
        var valid: Bool = false
    }
    
    struct ReadFileFS {
        var group = DispatchGroup()
        var chunkOffset: UInt32 = 0
        var totalLength: UInt32  = 0
        var chunkLength: UInt32  = 0
        var data = Data()
        var completed : Bool = false
        var valid : Bool = false
    }
    
    struct InformationFS {
        var group = DispatchGroup()
        var dirList: DirList = DirList()
        var valid: Bool = false
    }
    
    struct DirList {
        var parentPath = ""
        var ls: [Dir] = []
        var valid: Bool = false
    }
    
    struct Dir {
        var modificationTime: Int = 0
        var fileSize: Int = 0
        var flags: Int = 0
        var pathNames: String = ""
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
        
        case mv = 0x60
        case mvResponse = 0x61
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
    }
    
    @Published var progress: Int = 0
    @Published var externalResourcesSize: Int = 0
    
    func uploadExternalResources(completion: @escaping() -> Void) {
        DispatchQueue.global(qos: .default).async { [self] in
            do {
                let unzipDirectory = try Zip.quickUnzipFile(dfuUpdater.resourceURL)
                let jsonFilePath = unzipDirectory.appendingPathComponent("resources.json")
                let jsonData = try Data(contentsOf: jsonFilePath)
                
                let decoder = JSONDecoder()
                let resources = try decoder.decode(ResourcesJSON.self, from: jsonData)
                
                var newExternalResourcesSize = 0
                var fileIndex = 0
                
                // Loop over resources and calculate the size of each file
                for resource in resources.resources {
                    let fileDataPath = unzipDirectory.appendingPathComponent(resource.filename)
                    let fileData = try Data(contentsOf: fileDataPath)
                    
                    newExternalResourcesSize += fileData.count
                }
                
                DispatchQueue.main.async {
                    self.externalResourcesSize = newExternalResourcesSize
                }
                
                // Process each resource: create directory and write file
                for resource in resources.resources {
                    createDir(path: resource.path)
                    let fileDataPath = unzipDirectory.appendingPathComponent(resource.filename)
                    let fileData = try Data(contentsOf: fileDataPath)
                    
                    DispatchQueue.main.async {
                        fileIndex += 1
                        self.dfuUpdater.dfuState = "Uploading file \(fileIndex)"
                    }
                    
                    let writeFileFS = writeFile(data: fileData, path: resource.path, offset: 0)
                    writeFileFS.group.notify(queue: .main) {
                        if resources.resources.count < fileIndex {
                            self.dfuUpdater.dfuState = "Starting file \(fileIndex + 1)"
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if DownloadManager.shared.externalResources {
                        self.dfuUpdater.transferCompleted = true
                        self.dfuUpdater.firmwareSelected = false
                        self.dfuUpdater.resourceFilename = ""
                    }
                    
                    self.dfuUpdater.dfuState = "Completing uploads"
                    
                    completion()
                }
            } catch {
                log("Error parsing resources", caller: "BLEFSHandler", target: .ble)
            }
        }
    }
    
    private func createDir(path: String) {
        let dir = path.components(separatedBy: "/").filter { $0 != "" }
        
        if dir.count > 1 {
            var dirList : [String] = []
            var newDir = ""
            for idx in 0...dir.count-2 {
                newDir = newDir + "/" + dir[idx]
                dirList.append(newDir)
            }
            
            for makePath in dirList {
                let _ = makeDir(path: makePath)
            }
        }
    }

    func readFile(path: String, offset: UInt32) -> ReadFileFS {
        var writeData = Data()
        
        readFileFS = ReadFileFS()
        readFileFS.group = DispatchGroup()
        readFileFS.group.enter()

        writeData.append(Commands.readInit.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))
        
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: offset))
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: 490))

        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)

        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        readFileFS.group.wait()
        
        while !readFileFS.completed {
            readFileFS.group.enter()
            writeData = Data()
            
            writeData.append(Commands.readData.rawValue)
            writeData.append(Responses.ok.rawValue)
            
            writeData.append(Commands.padding.rawValue)
            writeData.append(Commands.padding.rawValue)
            
            writeData.append(contentsOf: convertUInt32ToUInt8Array(value: readFileFS.chunkOffset + readFileFS.chunkLength))
            writeData.append(contentsOf: convertUInt32ToUInt8Array(value: 490))
            
            bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
            readFileFS.group.wait()
        }
        
        return readFileFS
    }

    func writeFile(data: Data, path: String, offset: UInt32) -> WriteFileFS {
        var write = WriteFileFS()
        write.group = DispatchGroup()
        write.group.enter()
        var writeData = Data()

        writeData.append(Commands.write.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))
        
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: offset))
        writeData.append(contentsOf: timeSince1970())
        
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: UInt32(data.count)))

        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)

        writeFileFS = write
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
//        writeFileFS.group.wait()
        
        var dataQueue = data
        var newOffset = 0
        // FIXME: this line needs to be removed if we're uploading multiple files and want to show the overall progress percentage
        self.progress = 0
        
        while !writeFileFS.completed {
            writeFileFS.group.enter()
            writeData = Data()
            
            writeData.append(Commands.writeData.rawValue)
            writeData.append(Responses.ok.rawValue)
            
            writeData.append(Commands.padding.rawValue)
            writeData.append(Commands.padding.rawValue)
            
            var dataToSend : Data = Data()
            for _ in 0...170-1 {
                if dataQueue.count > 0 {
                    dataToSend.append(dataQueue.removeFirst())
                } else {
                    break
                }
            }
            
            //print("dataToSend: \(dataToSend.hexString)")
            //print("chunkOffset: \(newOffset)")
            
            writeData.append(contentsOf: convertUInt32ToUInt8Array(value: UInt32(newOffset)))
            writeData.append(contentsOf: convertUInt32ToUInt8Array(value: UInt32(dataToSend.count)))
            writeData.append(contentsOf: dataToSend)
            
            bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
//            writeFileFS.group.wait()
            
            newOffset += dataToSend.count
            let newProgress = progress + dataToSend.count
            DispatchQueue.main.async {
                self.progress = newProgress
            }
            //writeFileFS.offset = writeFileFS.offset + dataToSend.count
            //print("Count: \(data.count), Offset: \(newOffset)")
            
            //print("progress: \((round(Double(progress)/Double(externalResourcesSize))*100))%")
            
            //print("Progress: \(progress), Size: \(externalResourcesSize)")
            
            if UInt32(data.count) == newOffset {
                writeFileFS.completed = true
            }
        }
        
        return writeFileFS
    }

    func deleteFile(path: String) -> Bool {
        var rm = InformationFS()
        rm.group = DispatchGroup()
        rm.group.enter()
        var writeData = Data()

        writeData.append(Commands.delete.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))
        
        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)

        informationTransfer.append(rm)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTransfer[0].group.wait()
        let isValid = informationTransfer[0].valid
        informationTransfer.removeFirst()
        return isValid
    }
    
    func makeDir(path: String) -> Bool {
        var mk = InformationFS()
        mk.group = DispatchGroup()
        mk.group.enter()
        var writeData = Data()

        writeData.append(Commands.mkdir.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))

        writeData.append(Commands.padding.rawValue)
        writeData.append(Commands.padding.rawValue)
        writeData.append(Commands.padding.rawValue)
        writeData.append(Commands.padding.rawValue)
        writeData.append(contentsOf: timeSince1970())

        
        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)
        
        informationTransfer.append(mk)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTransfer[0].group.wait()
        let isValid = informationTransfer[0].valid
        informationTransfer.removeFirst()
        return isValid
    }

    func listDir(path: String) -> DirList {
        var ls = InformationFS()
        ls.group = DispatchGroup()
        ls.group.enter()
        var writeData = Data()

        writeData.append(Commands.ls.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))

        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)
        
        ls.dirList.parentPath = path
        informationTransfer.append(ls)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTransfer[0].group.wait()
        ls = informationTransfer[0]
        informationTransfer.removeFirst()
        return ls.dirList
    }

    func moveFileOrDir(oldPath: String, newPath: String) -> Bool {
        var mv = InformationFS()
        mv.group = DispatchGroup()
        mv.group.enter()
        var writeData = Data()

        writeData.append(Commands.mv.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(oldPath.count & 0x00FF))
        writeData.append(UInt8((oldPath.count & 0xFF00) >> 8))
        
        writeData.append(UInt8(newPath.count & 0x00FF))
        writeData.append(UInt8((newPath.count & 0xFF00) >> 8))
        
        let oldPathData = oldPath.data(using: .utf8)!
        let newPathData = newPath.data(using: .utf8)!
        
        writeData.append(oldPathData)
        writeData.append(Commands.padding.rawValue)
        writeData.append(newPathData)

        informationTransfer.append(mv)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTransfer[0].group.wait()
        let isValid = informationTransfer[0].valid
        informationTransfer.removeFirst()
        return isValid
    }

    func handleResponse(responseData: [UInt8] ) {
        if responseData[0] == Commands.readResponse.rawValue {
            switch responseData[1] {
            case Responses.ok.rawValue:
                let chunkOffset: UInt32 = UInt32(responseData[7]) << 24 | UInt32(responseData[6]) << 16 | UInt32(responseData[5]) << 8 | UInt32(responseData[4])
                let totalLength: UInt32 = UInt32(responseData[11]) << 24 | UInt32(responseData[10]) << 16 | UInt32(responseData[9]) << 8 | UInt32(responseData[8])
                let chunkLength: UInt32 = UInt32(responseData[15]) << 24 | UInt32(responseData[14]) << 16 | UInt32(responseData[13]) << 8 | UInt32(responseData[12])
                
                readFileFS.chunkOffset = chunkOffset
                readFileFS.totalLength = totalLength
                readFileFS.chunkLength = chunkLength
                
                if responseData.count > 16 {
                    for idx in 16...responseData.count - 1 {
                        readFileFS.data.append(responseData[idx])
                    }
                } else {
                    log("Error reading response--chunkOffset: \(chunkOffset), chunkLength: \(chunkLength), totalLength: \(totalLength)", caller: "BLEFSHandler", target: .ble)
                    readFileFS.valid = false
                    readFileFS.completed = true
                    return
                }
                
                if chunkOffset + chunkLength == totalLength {
                    readFileFS.completed = true
                    readFileFS.valid = true
                }
            case Responses.error.rawValue:
                readFileFS.completed = true
                log("Error response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.noFile.rawValue:
                readFileFS.completed = true
                log("No file response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.protocolError.rawValue:
                readFileFS.completed = true
                log("Protocol error response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.readOnly.rawValue:
                readFileFS.completed = true
                log("Read only response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.dirNotEmptyError.rawValue:
                readFileFS.completed = true
                log("Directory not empty response from BLE FS", caller: "BLEFSHandler", target: .ble)
            default:
                readFileFS.completed = true
                log("Unknown response from BLE FS with code: \(responseData[1])", caller: "BLEFSHandler", target: .ble)
            }
            readFileFS.group.leave()
        } else if responseData[0] == Commands.writeResponse.rawValue {
            switch responseData[1] {
            case Responses.ok.rawValue:
//                let offset: UInt32 = UInt32(responseData[7]) << 24 | UInt32(responseData[6]) << 16 | UInt32(responseData[5]) << 8 | UInt32(responseData[4])
                let freeSpace: UInt32 = UInt32(responseData[18]) << 24 | UInt32(responseData[17]) << 16 | UInt32(responseData[16]) << 8 | UInt32(responseData[15])
                
                //writeFileFS.offset = offset
                writeFileFS.freeSpace = freeSpace

                writeFileFS.valid = true
            case Responses.error.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("Error response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.noFile.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("No file response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.protocolError.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("Protocol error response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.readOnly.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("Read only response from BLE FS", caller: "BLEFSHandler", target: .ble)
            case Responses.dirNotEmptyError.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("Directory not empty response from BLE FS", caller: "BLEFSHandler", target: .ble)
            default:
                writeFileFS.completed = true
                writeFileFS.valid = false
                log("Unknown error response from BLE FS", caller: "BLEFSHandler", target: .ble)
            }
//            writeFileFS.group.leave()
        } else if responseData[0] == Commands.mvResponse.rawValue || responseData[0] == Commands.mkdirResponse.rawValue || responseData[0] == Commands.deleteResponse.rawValue {
            switch responseData[1] {
            case Responses.ok.rawValue:
                informationTransfer[0].valid = true
            default:
                break
                //print("error response code \(responseData[1])")
            }
            informationTransfer[0].group.leave()
        } else if responseData[0] == Commands.lsResponse.rawValue {
            switch responseData[1] {
            case Responses.ok.rawValue:
                let filePathLength: UInt16 = (UInt16(responseData[3]) << 8) | UInt16(responseData[2])
                let entryNumber: UInt32 = UInt32(responseData[7]) << 24 | UInt32(responseData[6]) << 16 | UInt32(responseData[5]) << 8 | UInt32(responseData[4])
                let totalEntryNumber: UInt32 = UInt32(responseData[11]) << 24 | UInt32(responseData[10]) << 16 | UInt32(responseData[9]) << 8 | UInt32(responseData[8])
                let flags: UInt32 = UInt32(responseData[15]) << 24 | UInt32(responseData[14]) << 16 | UInt32(responseData[13]) << 8 | UInt32(responseData[12])
                let modificationTime: UInt64 = UInt64(responseData[23]) << 56 | UInt64(responseData[22]) << 48 | UInt64(responseData[21]) << 40 | UInt64(responseData[20]) << 32 | UInt64(responseData[19]) << 24 | UInt64(responseData[18]) << 16 | UInt64(responseData[17]) << 8 | UInt64(responseData[16])
                let fileSize: UInt32 = UInt32(responseData[27]) << 24 | UInt32(responseData[26]) << 16 | UInt32(responseData[25]) << 8 | UInt32(responseData[24])

                if entryNumber == 0 {
                    informationTransfer[0].dirList.ls = []
                } else if entryNumber == totalEntryNumber {
                    informationTransfer[0].dirList.valid = true
                    informationTransfer[0].group.leave()
                    return
                }
                let filePath = responseData.suffix(Int(filePathLength))
                    
                if let decodedString = String(data: Data(filePath), encoding: .utf8) {
                    var dir = Dir()
                    dir.modificationTime = Int(modificationTime)
                    dir.fileSize = Int(fileSize)
                    dir.flags = Int(flags)
                    dir.pathNames = decodedString
                    informationTransfer[0].dirList.ls.append(dir)
                } else {
                    print("Decoding failed.")
                }
                
            case Responses.error.rawValue:
                informationTransfer[0].group.leave()
                log("Error response from BLE FS", caller: "BLEFSHandler")
            case Responses.noFile.rawValue:
                informationTransfer[0].group.leave()
                log("No file response from BLE FS", caller: "BLEFSHandler")
            case Responses.protocolError.rawValue:
                informationTransfer[0].group.leave()
                log("Protocol error response from BLE FS", caller: "BLEFSHandler")
            case Responses.readOnly.rawValue:
                informationTransfer[0].group.leave()
                log("Read only response from BLE FS", caller: "BLEFSHandler")
            case Responses.dirNotEmptyError.rawValue:
                informationTransfer[0].group.leave()
                log("Directory not empty response from BLE FS", caller: "BLEFSHandler")
            default:
                informationTransfer[0].group.leave()
                log("Unknown error response from BLE FS with response code: \(responseData[1])", caller: "BLEFSHandler")
            }
        }
    }
    
    func timeSince1970() -> [UInt8] {
        let timeInterval = NSDate().timeIntervalSince1970
        let val64 : UInt64 = UInt64(round(timeInterval))

        let byte1 = UInt8(val64 & 0x00000000000000FF)
        let byte2 = UInt8((val64 & 0x000000000000FF00) >> 8)
        let byte3 = UInt8((val64 & 0x0000000000FF0000) >> 16)
        let byte4 = UInt8((val64 & 0x00000000FF000000) >> 24)
        let byte5 = UInt8((val64 & 0x000000FF00000000) >> 32)
        let byte6 = UInt8((val64 & 0x0000FF0000000000) >> 40)
        let byte7 = UInt8((val64 & 0x00FF000000000000) >> 48)
        let byte8 = UInt8((val64 & 0xFF00000000000000) >> 56)
        
        return [byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8]
    }
    
    func convertUInt32ToUInt8Array(value: UInt32) -> [UInt8] {
        let byte1 = UInt8(value & 0x000000FF)
        let byte2 = UInt8((value & 0x0000FF00) >> 8)
        let byte3 = UInt8((value & 0x00FF0000) >> 16)
        let byte4 = UInt8((value & 0xFF000000) >> 24)
        return [byte1, byte2, byte3, byte4]
    }
    
    func readFile(_ filePath: String, completion: @escaping(Data) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let readFile = self.readFile(path: filePath, offset: 0)
            
            readFile.group.notify(queue: .main) {
                completion(readFile.data)
            }
        }
    }
    
    func readSettings(completion: @escaping(Settings) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let readFile = self.readFile(path: "/settings.dat", offset: 0)
            let firmwareVersion = DeviceManager.shared.firmware
            
            let settings = readFile.data.withUnsafeBytes { ptr -> Settings in
                guard let baseAddress = ptr.baseAddress else {
                    return Settings()
                }
                
                switch firmwareVersion {
                case "1.14.0":
                    let settings = baseAddress.load(as: Settings14.self)
                    
                    return Settings(
                        version: settings.version,
                        stepsGoal: settings.stepsGoal,
                        screenTimeOut: settings.screenTimeOut,
                        alwaysOnDisplay: false,
                        clockType: settings.clockType,
                        weatherFormat: settings.weatherFormat,
                        notificationStatus: settings.notificationStatus,
                        watchFace: settings.watchFace,
                        chimesOption: settings.chimesOption,
                        pineTimeStyle: settings.pineTimeStyle,
                        watchFaceInfineat: settings.watchFaceInfineat,
                        wakeUpMode: settings.wakeUpMode,
                        shakeWakeThreshold: settings.shakeWakeThreshold,
                        brightLevel: settings.brightLevel
                    )
                default:
                    return baseAddress.load(as: Settings.self)
                }
            }
            
            completion(settings)
        }
    }
    
    func convertDataToReadableFile(data: Data, fileExtension: String) throws -> Any {
        switch fileExtension.lowercased() {
        case "txt":
            if let text = String(data: data, encoding: .utf8) {
                return text
            } else {
                throw FileConversionError.dataConversionFailed
            }
        case "csv":
            if let csvString = String(data: data, encoding: .utf8) {
                let rows = csvString.components(separatedBy: "\n").filter { !$0.isEmpty }
                let csvData = rows.map { $0.components(separatedBy: ",") }
                
                return csvData
            } else {
                throw FileConversionError.dataConversionFailed
            }
        default:
            return data
        }
    }
    
    func jsonToMultilineString(_ data: Data) -> String? {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return formatDictionaryAsMultilineString(jsonObject)
            } else if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any] ] {
                return formatArrayAsMultilineString(jsonArray)
            } else {
                return "Invalid JSON format."
            }
        } catch {
            log("Error deserializing JSON", caller: "BLEFSHandler")
            print("Error deserializing JSON: \(error)")
            return nil
        }
    }
    
    func formatDictionaryAsMultilineString(_ dict: [String: Any], indent: String = "") -> String {
        var result = ""
        for (key, value) in dict {
            result += "\(indent)\(key): "
            
            if let nestedDict = value as? [String: Any] {
                result += "\n" + formatDictionaryAsMultilineString(nestedDict, indent: indent + "    ")
            } else if let array = value as? [[String: Any]] {
                result += "\n" + formatArrayAsMultilineString(array, indent: indent + "    ")
            } else {
                result += "\(value)\n"
            }
        }
        return result
    }
    
    func formatArrayAsMultilineString(_ array: [[String: Any]], indent: String = "") -> String {
        var result = ""
        for item in array {
            result += "\(indent)- "
            result += "\n" + formatDictionaryAsMultilineString(item, indent: indent + "  ")
        }
        return result
    }
    
    private func serializeSettings(_ settings: Settings) -> Data {
        var data = Data()
        
        data.append(contentsOf: convertUInt32ToUInt8Array(value: settings.version))
        data.append(contentsOf: convertUInt32ToUInt8Array(value: settings.stepsGoal))
        data.append(contentsOf: convertUInt32ToUInt8Array(value: settings.screenTimeOut))
        
        data.append(settings.clockType.rawValue)
        data.append(settings.weatherFormat.rawValue)
        data.append(settings.notificationStatus.rawValue)
        data.append(settings.watchFace)
        data.append(settings.chimesOption.rawValue)
        
        data.append(settings.pineTimeStyle.ColorTime.rawValue)
        data.append(settings.pineTimeStyle.ColorBar.rawValue)
        data.append(settings.pineTimeStyle.ColorBG.rawValue)
        data.append(settings.pineTimeStyle.gaugeStyle.rawValue)
        data.append(settings.pineTimeStyle.weatherEnable.rawValue)
        
        data.append(settings.watchFaceInfineat.showSideCover ? 1 : 0)
        data.append(settings.watchFaceInfineat.colorIndex)
        
        data.append(settings.wakeUpMode.rawValue)
        data.append(contentsOf: convertUInt16ToUInt8Array(value: settings.shakeWakeThreshold))
        data.append(settings.brightLevel.rawValue)
        
        return data
    }
    
    private func convertUInt16ToUInt8Array(value: UInt16) -> [UInt8] {
        return [
            UInt8((value & 0xFF00) >> 8),
            UInt8(value & 0x00FF)
        ]
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

struct Settings14 {
    var version: UInt32 = 4
    var stepsGoal: UInt32 = 10000
    var screenTimeOut: UInt32 = 15000
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
}

enum FileConversionError: Error {
    case unsupportedFileType
    case dataConversionFailed
}
