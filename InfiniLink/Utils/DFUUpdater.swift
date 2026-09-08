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

    let bleManager = BLEManager.shared
    let downloadManager = DownloadManager.shared

    private var dfuController: DFUServiceController?
    private var isAccessingScopedResource = false

    @Published var dfuState = ""
    @Published var percentComplete: Double = 0
    @Published var transferCompleted = false
    @Published var isUpdatingResources = false
    @Published var error: String?

    @Published var firmwareFilename = ""
    @Published var resourceFilename = ""
    @Published var firmwareSelected = false
    @Published var local = true
    @Published var firmwareURL: URL!
    @Published var resourceURL: URL!

    @AppStorage("updateResourcesWithFirmware") var updateResourcesWithFirmware = true

    func fileSize(from fileUrl: URL) -> Int {
        do {
            let resource = try fileUrl.resourceValues(forKeys: [.fileSizeKey])
            return resource.fileSize ?? 0
        } catch {
            log("Error getting file size: \(error.localizedDescription)", caller: "DFUUpdater", target: .dfu)
        }

        return 0
    }

    func downloadTransfer() {
        if !local, resourceURL != nil {
            isUpdatingResources = true
            dfuState = NSLocalizedString("Updating resources", comment: "")

            BLEFSHandler.shared.uploadExternalResources { [self] in
                isUpdatingResources = false
                updateFirmware()
            }
        } else {
            updateFirmware()
        }
    }

    func updateFirmware() {
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

        let initiator = DFUServiceInitiator().with(firmware: firmware)
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self

        error = nil
        bleManager.beginFirmwareUpdate()
        dfuController = initiator.start(target: target)
    }

    func stopTransfer(abort: Bool) {
        if abort {
            _ = dfuController?.abort()
        }

        finish(success: false)
    }

    func dismissError() {
        error = nil
        downloadManager.updateStarted = false
    }

    private func fail(_ message: String) {
        log(message, caller: "DFUUpdater", target: .dfu)
        error = message
        finish(success: false)
    }

    private func finish(success: Bool) {
        dfuController = nil

        if isAccessingScopedResource {
            firmwareURL?.stopAccessingSecurityScopedResource()
            isAccessingScopedResource = false
        }

        dfuState = ""
        percentComplete = 0
        isUpdatingResources = false
        transferCompleted = success

        if success {
            firmwareSelected = false
            downloadManager.updateAvailable = false
        }

        // Keep the progress view up when there's an error to show; otherwise close it
        if error == nil {
            downloadManager.updateStarted = false
        }

        bleManager.endFirmwareUpdate()
    }

    func dfuStateDidChange(to state: DFUState) {
        dfuState = state.description

        switch state {
        case .completed:
            log("Firmware update completed", type: .info, caller: "DFUUpdater", target: .dfu)
            finish(success: true)
        case .aborted:
            log("Firmware update aborted", type: .info, caller: "DFUUpdater", target: .dfu)
            finish(success: false)
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
