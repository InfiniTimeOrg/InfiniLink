//
//  BLE_FS.swift
//  InfiniLink
//
//  Created by Alex Emry on 1/7/22.
//
//

import CoreBluetooth
import SwiftyJSON
import Zip
import SwiftUI

class BLEFSHandler : ObservableObject {
    static var shared = BLEFSHandler()
    let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
    
    var informationTrandfer : [InformationFS] = []
    var readFileFS : ReadFileFS = ReadFileFS()
    var writeFileFS : WriteFileFS = WriteFileFS()
    
    struct WriteFileFS {
        var group = DispatchGroup()
        var offset : Int = 0
        var freeSpace : UInt32  = 0
        var data = Data()
        var completed : Bool = false
        var valid : Bool = false
    }
    
    struct ReadFileFS {
        var group = DispatchGroup()
        var chunkOffset : UInt32 = 0
        var totalLength : UInt32  = 0
        var chunkLength : UInt32  = 0
        var data = Data()
        var completed : Bool = false
        var valid : Bool = false
    }
    
    struct InformationFS {
        var group = DispatchGroup()
        var dirList : DirList = DirList()
        var valid : Bool = false
    }
    
    struct DirList {
        var parentPath = ""
        var ls : [Dir] = []
        var valid : Bool = false
    }
    
    struct Dir {
        var modificationTime : Int = 0
        var fileSize : Int = 0
        var flags : Int = 0
        var pathNames : String = ""
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
    
    @Published var progress : Int = 0
    @Published var externalResourcesSize : Int = 0
    
    @AppStorage("lockNavigation") var lockNavigation = false
    
    func downloadTransfer() {
        DispatchQueue.global(qos: .default).async { [self] in
            do {
                let unzipDirectory = try Zip.quickUnzipFile(DFU_Updater.shared.firmwareURL)
                let jsonFilePath = unzipDirectory.appendingPathComponent("resources.json")
                let jsonData = try Data(contentsOf: jsonFilePath)
                let json = try JSON(data: jsonData)
                
                var newExternalResourcesSize = 0
                
                for idx in 0...json["resources"].count-1 {
                    let fileDataPath = unzipDirectory.appendingPathComponent(json["resources"][idx]["filename"].stringValue)
                    let fileData = try Data(contentsOf: fileDataPath)
                    
                    newExternalResourcesSize += fileData.count
                }
                
                DispatchQueue.main.async {
                    self.externalResourcesSize = newExternalResourcesSize
                }
                
                for idx in 0...json["resources"].count-1 {
                    createDir(path: json["resources"][idx]["path"].stringValue)
                    let fileDataPath = unzipDirectory.appendingPathComponent(json["resources"][idx]["filename"].stringValue)
                    let fileData = try Data(contentsOf: fileDataPath)
                    let _ = writeFile(data: fileData, path: json["resources"][idx]["path"].stringValue, offset: 0)
                }
                
                DispatchQueue.main.async {
                    DFU_Updater.shared.transferCompleted = true
                    DFU_Updater.shared.firmwareSelected = false
                    DFU_Updater.shared.resourceFilename = ""
                    self.lockNavigation = false
                }
            } catch {
                print("Something went wrong")
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
        var read = ReadFileFS()
        read.group = DispatchGroup()
        read.group.enter()
        var writeData = Data()

        writeData.append(Commands.readInit.rawValue)
        writeData.append(Commands.padding.rawValue)

        writeData.append(UInt8(path.count & 0x00FF))
        writeData.append(UInt8((path.count & 0xFF00) >> 8))
        
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: offset))
        writeData.append(contentsOf: convertUInt32ToUInt8Array(value: 490))

        let pathData = path.data(using: .utf8)!
        writeData.append(pathData)

        readFileFS = read
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
        
        //print(readFileFS.data.hexString)
        
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
        writeFileFS.group.wait()
        
        var dataQueue = data
        var newOffset = 0
        
        while !writeFileFS.completed {
            writeFileFS.group.enter()
            writeData = Data()
            
            writeData.append(Commands.writeData.rawValue)
            writeData.append(Responses.ok.rawValue)
            
            writeData.append(Commands.padding.rawValue)
            writeData.append(Commands.padding.rawValue)
            
            var dataToSend : Data = Data()
            for _ in 0...128-1 {
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
            writeFileFS.group.wait()
            
            newOffset += dataToSend.count
            let newProgress = progress + dataToSend.count
            DispatchQueue.main.async {
                self.progress = newProgress
            }
            //writeFileFS.offset = writeFileFS.offset + dataToSend.count
            //print("Count: \(data.count), Offset: \(writeFileFS.offset)")
            
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

        informationTrandfer.append(rm)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTrandfer[0].group.wait()
        let isValid = informationTrandfer[0].valid
        informationTrandfer.removeFirst()
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
        
        informationTrandfer.append(mk)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTrandfer[0].group.wait()
        let isValid = informationTrandfer[0].valid
        informationTrandfer.removeFirst()
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
        informationTrandfer.append(ls)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTrandfer[0].group.wait()
        ls = informationTrandfer[0]
        informationTrandfer.removeFirst()
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

        informationTrandfer.append(mv)
        bleManager.infiniTime.writeValue(writeData, for: BLEManager.shared.blefsTransfer!, type: .withResponse)
        
        informationTrandfer[0].group.wait()
        let isValid = informationTrandfer[0].valid
        informationTrandfer.removeFirst()
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
                
                
                if responseData.count > 16 {for idx in 16...responseData.count-1 {
                        readFileFS.data.append(responseData[idx])
                    }
                } else {
                    print("ERROR: debug info - chunkOffset: \(chunkOffset), chunkLength: \(chunkLength), totalLength: \(totalLength)")
                    readFileFS.valid = false
                    readFileFS.completed = true
                    return
                }
                
                print("chunkOffset: \(chunkOffset), chunkLength: \(chunkLength), totalLength: \(totalLength)")
                
                if chunkOffset + chunkLength == totalLength {
                    readFileFS.completed = true
                    readFileFS.valid = true
                }
            case Responses.error.rawValue:
                readFileFS.completed = true
                print("error")
            case Responses.noFile.rawValue:
                readFileFS.completed = true
                print("no file")
            case Responses.protocolError.rawValue:
                readFileFS.completed = true
                print("protocol error")
            case Responses.readOnly.rawValue:
                readFileFS.completed = true
                print("read only")
            case Responses.dirNotEmptyError.rawValue:
                readFileFS.completed = true
                print("dir not empty")
            default:
                readFileFS.completed = true
                print("unknown error, response code \(responseData[1])")
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
                print("error")
            case Responses.noFile.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                print("no file")
            case Responses.protocolError.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                print("protocol error")
            case Responses.readOnly.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                print("read only")
            case Responses.dirNotEmptyError.rawValue:
                writeFileFS.completed = true
                writeFileFS.valid = false
                print("dir not empty")
            default:
                writeFileFS.completed = true
                writeFileFS.valid = false
                print("unknown error, response code \(responseData[1])")
            }
            writeFileFS.group.leave()
        } else if responseData[0] == Commands.mvResponse.rawValue || responseData[0] == Commands.mkdirResponse.rawValue || responseData[0] == Commands.deleteResponse.rawValue {
            switch responseData[1] {
            case Responses.ok.rawValue:
                informationTrandfer[0].valid = true
            default: break
                //print("error response code \(responseData[1])")
            }
            informationTrandfer[0].group.leave()
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
                    informationTrandfer[0].dirList.ls = []
                } else if entryNumber == totalEntryNumber {
                    informationTrandfer[0].dirList.valid = true
                    informationTrandfer[0].group.leave()
                    return
                }
                let filePath = responseData.suffix(Int(filePathLength))
                    
                if let decodedString = String(data: Data(filePath), encoding: .utf8) {
                    var dir = Dir()
                    dir.modificationTime = Int(modificationTime)
                    dir.fileSize = Int(fileSize)
                    dir.flags = Int(flags)
                    dir.pathNames = decodedString
                    informationTrandfer[0].dirList.ls.append(dir)
                } else {
                    print("Decoding failed.")
                }
                
            case Responses.error.rawValue:
                informationTrandfer[0].group.leave()
                print("error")
            case Responses.noFile.rawValue:
                informationTrandfer[0].group.leave()
                print("no file")
            case Responses.protocolError.rawValue:
                informationTrandfer[0].group.leave()
                print("protocol error")
            case Responses.readOnly.rawValue:
                informationTrandfer[0].group.leave()
                print("read only")
            case Responses.dirNotEmptyError.rawValue:
                informationTrandfer[0].group.leave()
                print("dir not empty")
            default:
                informationTrandfer[0].group.leave()
                //print("unknown error, response code \(responseData[1])")
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
}
