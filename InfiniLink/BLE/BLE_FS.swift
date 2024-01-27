//
//  BLE_FS.swift
//  InfiniLink
//
//  Created by Alex Emry on 1/7/22.
//
//

import CoreBluetooth

/** TODO:
    - read file
    - write file
    - delete file
    - make directory
    - list directory
    - move file or directory
*/
class BLEFSHandler {
    static var shared = BLEFSHandler()
    let bleManager = BLEManager.shared
    let transferCharacteristic = BLEManager.shared.blefsTransfer

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

    func readFile() {
        //var header = Data()
    }

    func writeFile(){
        // TODO
    }

    func deleteFile() {
        // TODO
    }

    func makeDir() {
        // TODO
    }

    func listDir(path: String) {
        var writeData = Data()

        // add heading
        writeData.append(Commands.ls.rawValue)
        writeData.append(Commands.padding.rawValue)

        // compute path length and append to writeData

        let dirLength = UInt16(NSString(string: path).length)
        let dirLengthBytes = Data(withUnsafeBytes(of: dirLength.bigEndian, {
            Array($0)
        }))
        print(writeData.hexString)
        print(dirLengthBytes.hexString)

        writeData.append(contentsOf: dirLengthBytes)

        let pathData = path.data(using: .utf8)!
        print(pathData.hexString)
        writeData.append(pathData)

        print("final: \(writeData.hexString)")

        bleManager.infiniTime.writeValue(writeData, for: transferCharacteristic!, type: .withResponse)

    }

    func moveFileOrDir() {
        // TODO
    }

    func handleResponse(responseData: [UInt8] ) {
        if responseData[0] == UInt8(0x51) {
            print("ls response received!")
            switch responseData[1] {
            case Responses.ok.rawValue:
                print("success")
            case Responses.error.rawValue:
                print("error")
            case Responses.noFile.rawValue:
                print("no file")
            case Responses.protocolError.rawValue:
                print("protocol error")
            case Responses.readOnly.rawValue:
                print("read only")
            case Responses.dirNotEmptyError.rawValue:
                print("dir not empty")
            default:
                print("unknown error, response code \(responseData[1])")
            }
        }
    }
}
