//
//  DFU.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import Zip
import SwiftUI

class DFUUpdater: ObservableObject {
    static let shared = DFUUpdater()

    enum Stage: Equatable {
        case idle
        case downloading
        case uploadingResources
        case installing
        case failed(String)
    }

    let bleManager = BLEManager.shared
    let downloadManager = DownloadManager.shared

    private(set) var transfer: DFUTransfer?
    private var isAccessingScopedResource = false

    @Published private(set) var stage: Stage = .idle
    @Published var statusDetail = ""
    @Published var percentComplete: Double = 0

    @Published var firmwareFilename = ""
    @Published var resourceFilename = ""
    @Published var firmwareSelected = false
    @Published var local = true
    @Published var firmwareURL: URL!
    @Published var resourceURL: URL!

    @AppStorage("updateResourcesWithFirmware") var updateResourcesWithFirmware = true
    @AppStorage("dfuPacketReceiptNotification") var packetReceiptNotification = 0

    func fileSize(from fileUrl: URL) -> Int {
        do {
            let resource = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            return resource.fileSize ?? 0
        } catch {
            log("Error getting file size: \(error.localizedDescription)", caller: "DFUUpdater", target: .dfu)
        }

        return 0
    }

    // DownloadManager calls this while it pulls the zip(s) from GitHub
    func beginDownloading() {
        downloadManager.updateStarted = true
        stage = .downloading
        statusDetail = ""
        percentComplete = 0
    }

    // Everything is on disk now (either downloaded or in a local file)
    // push resources (if any) and then flash
    func install() {
        downloadManager.updateStarted = true

        if firmwareURL == nil, resourceURL != nil {
            installResourcesOnly()
        } else if !local, resourceURL != nil {
            uploadResources { [self] in installFirmware() }
        } else {
            installFirmware()
        }
    }

    // External-resources-only flow
    // push resources over BLEFS, no firmware flash
    func installResourcesOnly() {
        downloadManager.updateStarted = true
        uploadResources { [self] in finish(.completed) }
    }

    func cancel() {
        downloadManager.cancelActiveDownload()
        transfer?.cancel()
        finish(.cancelled)
    }

    func dismissError() {
        finish(.cancelled)
    }

    func reportDownloadFailure() {
        fail(NSLocalizedString("The update couldn't be downloaded.", comment: ""))
    }

    func reportResourceUploadFailure() {
        fail(NSLocalizedString("The watch's resources couldn't be updated.", comment: ""))
    }

    private func uploadResources(then next: @escaping () -> Void) {
        stage = .uploadingResources
        statusDetail = ""
        BLEFSHandler.shared.uploadExternalResources(completion: next)
    }

    private func installFirmware() {
        guard let firmwareURL else {
            fail(NSLocalizedString("The firmware file is missing.", comment: ""))
            return
        }
        guard let target = bleManager.infiniTime else {
            fail(NSLocalizedString("InfiniLink isn't connected to a watch.", comment: ""))
            return
        }

        if local {
            isAccessingScopedResource = firmwareURL.startAccessingSecurityScopedResource()
        }

        guard let controlPoint = bleManager.dfuControlPointCharacteristic, let packet = bleManager.dfuPacketCharacteristic else {
            fail(NSLocalizedString("The watch isn't ready for updates. Make sure file access and updates are allowed on it.", comment: ""))
            return
        }

        let package: (image: Data, initPacket: Data)
        do {
            package = try loadPackage(firmwareURL)
        } catch {
            fail(NSLocalizedString("The firmware file couldn't be read. Make sure it's a valid DFU zip.", comment: ""))
            return
        }

        stage = .installing
        statusDetail = ""
        percentComplete = 0

        let transfer = DFUTransfer(peripheral: target, controlPoint: controlPoint, packet: packet, image: package.image, initPacket: package.initPacket, packetsPerReceipt: UInt8(clamping: packetReceiptNotification))
        transfer.onStep = { [weak self] step in
            self?.statusDetail = self?.description(of: step) ?? ""
        }
        transfer.onProgress = { [weak self] progress in
            self?.percentComplete = progress * 100
        }
        transfer.onFinish = { [weak self] error in
            if let error {
                self?.fail(error)
            } else {
                log("Firmware update completed", type: .info, caller: "DFUUpdater", target: .dfu)
                self?.finish(.completed)
            }
        }
        self.transfer = transfer

        bleManager.beginFirmwareUpdate()
        transfer.start()
    }

    private func loadPackage(_ url: URL) throws -> (image: Data, initPacket: Data) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Zip.unzipFile(url, destination: directory, overwrite: true, password: nil)
        defer { try? FileManager.default.removeItem(at: directory) }

        var binFile: String?
        var datFile: String?
        if let data = try? Data(contentsOf: directory.appendingPathComponent("manifest.json")),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let application = (json["manifest"] as? [String: Any])?["application"] as? [String: Any] {
            binFile = application["bin_file"] as? String
            datFile = application["dat_file"] as? String
        }

        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        guard let bin = binFile ?? files.first(where: { $0.hasSuffix(".bin") }), let dat = datFile ?? files.first(where: { $0.hasSuffix(".dat") }) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return (try Data(contentsOf: directory.appendingPathComponent(bin)), try Data(contentsOf: directory.appendingPathComponent(dat)))
    }

    private func description(of step: DFUTransfer.Step) -> String {
        switch step {
        case .starting:
            return NSLocalizedString("Starting", comment: "")
        case .sendingInit:
            return NSLocalizedString("Preparing", comment: "")
        case .sendingImage:
            return NSLocalizedString("Installing", comment: "")
        case .validating:
            return NSLocalizedString("Verifying", comment: "")
        case .activating, .done:
            return NSLocalizedString("Restarting", comment: "")
        }
    }

    private enum Outcome { case completed, cancelled, failed }

    private func fail(_ message: String) {
        log(message, caller: "DFUUpdater", target: .dfu)
        finish(.failed, message: message)
    }

    private func finish(_ outcome: Outcome, message: String? = nil) {
        transfer = nil

        if isAccessingScopedResource {
            firmwareURL?.stopAccessingSecurityScopedResource()
            isAccessingScopedResource = false
        }

        statusDetail = ""
        percentComplete = 0
        bleManager.endFirmwareUpdate(installed: outcome == .completed)

        switch outcome {
        case .failed:
            stage = .failed(message ?? NSLocalizedString("The update failed.", comment: "")) // Keep the view up to show the error
        case .completed:
            firmwareSelected = false
            resourceFilename = ""
            resourceURL = nil
            downloadManager.updateAvailable = false
            downloadManager.updateStarted = false
            stage = .idle
        case .cancelled:
            downloadManager.updateStarted = false
            stage = .idle
        }
    }
}
