//
//  DFUUpdaterCustom.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/4/25.
//

import Foundation
import Zip

struct DFUManifest: Codable {
    struct InitPacketData: Codable {
        let application_version: Int
        let device_revision: Int
        let device_type: Int
        let firmware_crc16: Int
        let softdevice_req: [Int]
    }
    struct FirmwareApplication: Codable {
        let bin_file: String
        let dat_file: String
        let init_packet_data: InitPacketData
    }
    struct Manifest: Codable {
        let application: FirmwareApplication
        let dfu_version: Double
    }
    
    let manifest: Manifest
}

class DFUUpdaterCustom: ObservableObject {
    static let shared = DFUUpdaterCustom()
    
    let bleManager = BLEManager.shared
    let dfuUpdater = DFUUpdater.shared
    
    func startDFU() {
        let start = Data([0x01, 0x04])
        let initPacket = Data([0x02, 0x00])
        let datPacketSent = Data([0x02, 0x01])
        let packetReceiptInterval = Data([0x08, 0x0A])
        
        if let infiniTime = bleManager.infiniTime {
            /*
             MARK: Step One
            For the first step, write `0x01`, `0x04` to the control point characteristic. This will signal InfiniTime that a DFU upgrade is to be started.
             */
            infiniTime.writeValue(start, for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
            
            do {
                let unzipDirectory = try Zip.quickUnzipFile(dfuUpdater.firmwareURL)
                let manifest = unzipDirectory.appendingPathComponent("manifest.json")
                let jsonData = try Data(contentsOf: manifest)
                
                let decoder = JSONDecoder()
                let decodedManifest = try decoder.decode(DFUManifest.self, from: jsonData)

                /*
                 MARK: Step Two
                 In step two, send the total size in bytes of the firmware file to the packet characteristic. This value should be an unsigned 32-bit integer encoded as little-endian. In front of this integer should be 8 null bytes. This is because there are three items that can be updated and each 4 bytes is for one of those. The last four are for the InfiniTime application, so those are the ones that need to be set.
                 */
                let fileSize = try Data(contentsOf: unzipDirectory.appendingPathComponent(decodedManifest.manifest.application.bin_file)).count
                print("Firmware size: \(fileSize) bytes")
                
                var data = Data(repeating: 0, count: 8)
                let sizeBytes = withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Data($0) }
                data.append(sizeBytes)
                
                print("Data to send: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
                
                infiniTime.writeValue(data, for: bleManager.dfuPacketCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Three
                 Before running step three, wait for a response from the control point. This response should be `0x10`, `0x01`, `0x01` which indicates a successful DFU start. In step three, send `0x02`, `0x00` to the control point. This will signal InfiniTime to expect the init packet on the packet characteristic.
                 */
                // TODO: wait for response
                infiniTime.writeValue(initPacket, for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Four
                 The previous step prepared InfiniTime for this one. In this step, send the contents of the .dat init packet file to the packet characteristic.
                 */
                let datData = try Data(contentsOf: unzipDirectory.appendingPathComponent(decodedManifest.manifest.application.dat_file))
                infiniTime.writeValue(datData, for: bleManager.dfuPacketCharacteristic, type: .withResponse)
                /*
                 After this, send `0x02`, `0x01` indicating that the packet has been sent.
                 */
                infiniTime.writeValue(datPacketSent, for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Five
                 Before running this step, wait to receive `0x10`, `0x02`, `0x01` which indicates that the packet has been received. During this step, send the packet receipt interval to the control point. The firmware file will be sent in segments of 20 bytes each. The packet receipt interval indicates how many segments should be received before sending a receipt containing the amount of bytes received so that it can be confirmed to be the same as the amount sent. This is very useful for detecting packet loss. `itd` uses `0x08`, `0x0A` which indicates 10 segments.
                 */
                // TODO: wait for response
                infiniTime.writeValue(packetReceiptInterval, for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Six
                 Write `0x03` to the control point, indicating that the firmware will be sent next on the packet characteristic.
                 */
                infiniTime.writeValue(Data([0x03]), for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Seven
                 This step is the most difficult. Here, the actual firmware is sent to InfiniTime.
                 
                 As mentioned before, the firmware file must be split up into segments of 20 bytes each and sent to the packet characteristic one by one. Every 10 segments (or whatever you have set the interval to), check for a response starting with `0x11`. The rest of the response will be the amount of bytes received encoded as a little-endian unsigned 32-bit integer. Confirm that this matches the amount of bytes sent, and then continue sending more segments.
                 */
                let firmwareData = try Data(contentsOf: unzipDirectory.appending(path: decodedManifest.manifest.application.bin_file))
                let firmwareSegments = firmwareData.split(separator: Data([0x08, 0x0A]))
                
                for (_, segment) in firmwareSegments.enumerated() {
                    infiniTime.writeValue(segment, for: bleManager.dfuPacketCharacteristic, type: .withResponse)
                    // TODO: wait for response
                }
                
                /*
                 MARK: Step Eight
                 Before running this step, wait to receive `0x10`, `0x03`, `0x01` which indicates a successful receipt of the firmware image. In this step, write `0x04` to the control point to signal InfiniTime to validate the image it has received.
                 */
                infiniTime.writeValue(Data([0x04]), for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
                
                /*
                 MARK: Step Nine
                 Before running this step, wait to receive `0x10`, `0x04`, `0x01` which indicates that the image has been validated. In this step, send `0x05` to the control point as a command with no response. This signals InfiniTime to activate the new firmware and reboot.
                 */
                // TODO: wait for response
                infiniTime.writeValue(Data([0x05]), for: bleManager.dfuControlPointCharacteristic, type: .withResponse)
            } catch {
                log("\(error.localizedDescription)", caller: "DFUUpdaterCustom")
            }
        }
    }
}
