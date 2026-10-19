//
//  DFUTransfer.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import CoreBluetooth

// Follows the DFU steps in InfiniTime's doc/ble.md
class DFUTransfer {
    enum Step {
        case starting
        case sendingInit
        case sendingImage
        case validating
        case activating
        case done
    }

    private let peripheral: CBPeripheral
    private let controlPoint: CBCharacteristic
    private let packet: CBCharacteristic
    private let image: Data
    private let initPacket: Data
    private let packetsPerReceipt: UInt8

    var onStep: ((Step) -> Void)?
    var onProgress: ((Double) -> Void)?
    var onFinish: ((String?) -> Void)? // Called with nil on success, or a message describing the failure

    private(set) var step = Step.starting {
        didSet { onStep?(step) }
    }
    private var offset = 0
    private var packetsSinceReceipt = 0
    private var afterControlPointWrite: (() -> Void)?
    private var timeout: DispatchWorkItem?

    // InfiniTime only takes 20 byte packets
    private let chunkSize = 20

    init(peripheral: CBPeripheral, controlPoint: CBCharacteristic, packet: CBCharacteristic, image: Data, initPacket: Data, packetsPerReceipt: UInt8) {
        self.peripheral = peripheral
        self.controlPoint = controlPoint
        self.packet = packet
        self.image = image
        self.initPacket = initPacket
        self.packetsPerReceipt = packetsPerReceipt
    }

    func start() {
        step = .starting
        // The watch erases flash before it answers, so this can take a few seconds
        writeControlPoint([0x01, 0x04]) { [self] in
            // Softdevice and bootloader sizes are 0, we only send the app
            let size = UInt32(image.count)
            writePacket(Data(count: 8) + Data([UInt8(size & 0xFF), UInt8((size >> 8) & 0xFF), UInt8((size >> 16) & 0xFF), UInt8(size >> 24)]))
        }
    }

    func cancel() {
        // The watch cancels on its own after 10 seconds without data
        finish(nil, notify: false)
    }

    func connectionLost() {
        guard step != .done else { return }

        if step == .activating {
            finish(nil)
        } else {
            finish(NSLocalizedString("The watch disconnected during the update.", comment: ""))
        }
    }

    func didWriteControlPoint(error: Error?) {
        if let error, step != .activating {
            finish(error.localizedDescription)
            return
        }

        let next = afterControlPointWrite
        afterControlPointWrite = nil
        next?()
    }

    func didReceiveControlPoint(_ value: Data) {
        let bytes = [UInt8](value)
        guard step != .done, let opcode = bytes.first else { return }
        resetTimeout()

        if opcode == 0x11 {
            packetsSinceReceipt = 0
            sendImagePackets()
            return
        }
        guard opcode == 0x10, bytes.count >= 3 else { return }

        guard bytes[2] == 0x01 else {
            finish(String(format: NSLocalizedString("The watch rejected the update at step %d (error %d).", comment: ""), Int(bytes[1]), Int(bytes[2])))
            return
        }

        switch bytes[1] {
        case 0x01:
            step = .sendingInit
            writeControlPoint([0x02, 0x00]) { [self] in
                writePacket(initPacket)
                writeControlPoint([0x02, 0x01])
            }
        case 0x02:
            let startImage = { [self] in
                writeControlPoint([0x03]) { [self] in
                    step = .sendingImage
                    sendImagePackets()
                }
            }
            if packetsPerReceipt > 0 {
                writeControlPoint([0x08, packetsPerReceipt], then: startImage)
            } else {
                startImage()
            }
        case 0x03:
            step = .validating
            writeControlPoint([0x04])
        case 0x04:
            // The watch restarts right away so we might not get a response
            step = .activating
            writeControlPoint([0x05])
            finish(nil)
        default:
            break
        }
    }

    func peripheralIsReady() {
        sendImagePackets()
    }

    private func sendImagePackets() {
        guard step == .sendingImage else { return }

        let start = offset
        while offset < image.count && peripheral.canSendWriteWithoutResponse && (packetsPerReceipt == 0 || packetsSinceReceipt < Int(packetsPerReceipt)) {
            let end = min(offset + chunkSize, image.count)
            writePacket(image.subdata(in: offset..<end))
            offset = end
            packetsSinceReceipt += 1
        }
        // Without receipts, sending is the only sign of progress
        if offset > start {
            resetTimeout()
        }
        onProgress?(Double(offset) / Double(max(image.count, 1)))
    }

    private func writeControlPoint(_ bytes: [UInt8], then next: (() -> Void)? = nil) {
        afterControlPointWrite = next
        resetTimeout()
        peripheral.writeValue(Data(bytes), for: controlPoint, type: .withResponse)
    }

    private func writePacket(_ data: Data) {
        peripheral.writeValue(data, for: packet, type: .withoutResponse)
    }

    private func resetTimeout() {
        timeout?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.finish(NSLocalizedString("The watch stopped responding.", comment: ""))
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: work)
    }

    private func finish(_ error: String?, notify: Bool = true) {
        guard step != .done else { return }
        
        timeout?.cancel()
        timeout = nil
        afterControlPointWrite = nil
        step = .done
        
        if notify {
            onFinish?(error)
        }
    }
}
