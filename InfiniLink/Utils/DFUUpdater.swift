//
//  DFU.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import NordicDFU
import SwiftUI

class DFUUpdater: ObservableObject, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
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

    private var dfuController: DFUServiceController?
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
    @AppStorage("dfuPacketReceiptNotification") var packetReceiptNotification = 12

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
        _ = dfuController?.abort()
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

        let firmware: DFUFirmware
        do {
            firmware = try DFUFirmware(urlToZipFile: firmwareURL)
        } catch {
            fail(NSLocalizedString("The firmware file couldn't be read. Make sure it's a valid DFU zip.", comment: ""))
            return
        }

        stage = .installing
        statusDetail = ""
        percentComplete = 0

        let initiator = DFUServiceInitiator().with(firmware: firmware)
        initiator.packetReceiptNotificationParameter = UInt16(clamping: packetReceiptNotification)
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self

        bleManager.beginFirmwareUpdate()
        dfuController = initiator.start(target: target)
    }

    private enum Outcome { case completed, cancelled, failed }

    private func fail(_ message: String) {
        log(message, caller: "DFUUpdater", target: .dfu)
        finish(.failed, message: message)
    }

    private func finish(_ outcome: Outcome, message: String? = nil) {
        dfuController = nil

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

    func dfuStateDidChange(to state: DFUState) {
        statusDetail = state.description

        switch state {
        case .completed:
            log("Firmware update completed", type: .info, caller: "DFUUpdater", target: .dfu)
            finish(.completed)
        case .aborted:
            log("Firmware update aborted", type: .info, caller: "DFUUpdater", target: .dfu)
            finish(.cancelled)
        default:
            break
        }
    }

    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        fail(message)
    }

    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        percentComplete = Double(progress)
    }

    func logWith(_ level: LogLevel, message: String) {
        log("DFU log: \(message)", type: .info, caller: "DFUUpdater", target: .dfu)
    }
}
