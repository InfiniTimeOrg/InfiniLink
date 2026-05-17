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
	
    var bleManager = BLEManager.shared
	var downloadManager = DownloadManager.shared
	var dfuController: DFUServiceController!
	
	@Published var dfuState: String = ""
    @Published var transferCompleted = false
	@Published var isUpdatingResources = false
	@Published var percentComplete: Double = 0
	
	@Published var firmwareFilename = ""
    @Published var resourceFilename = ""
	@Published var firmwareSelected: Bool = false
    @Published var local = true
    @Published var firmwareURL: URL!
    @Published var resourceURL: URL!
    
    @AppStorage("updateResourcesWithFirmware") var updateResourcesWithFirmware = true
	
    func updateFirmware() {
        guard let infiniTime = bleManager.infiniTime else { return }
        guard let firmwareURL else {
            log("Firmware URL is nil or invalid")
            return
        }
        
        let _ = firmwareURL.startAccessingSecurityScopedResource()
        
        print(firmwareURL)
        
        do {
            let selectedFirmware = try DFUFirmware(urlToZipFile: firmwareURL.absoluteURL)
            
            let initiator = DFUServiceInitiator().with(firmware: selectedFirmware)
            
            initiator.packetReceiptNotificationParameter = 18 // default 12, this speeds up the transfer
            initiator.logger = self // to get log info
            initiator.delegate = self // to be informed about current state and errors
            initiator.progressDelegate = self // to show progress bar
            dfuController = initiator.start(target: infiniTime)
        } catch {
            print(error)
        }
        
    }
	
	func downloadTransfer() {
        if resourceURL != nil && !local {
            isUpdatingResources = true
            dfuState = "Updating resources"
            
            BLEFSHandler.shared.uploadExternalResources { [self] in
                isUpdatingResources = false
                updateFirmware()
            }
        } else {
            updateFirmware()
        }
	}
	
    func stopTransfer(abort: Bool) {
		if abort {
			_ = dfuController?.abort()
		}
        
        firmwareURL?.stopAccessingSecurityScopedResource()
        
        dfuController = nil
		dfuState = ""
        
		percentComplete = 0
        
        downloadManager.updateAvailable = false
        downloadManager.updateStarted = false
        firmwareSelected = false
        transferCompleted = false
	}
	
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state.description
        
        switch state {
        case .completed:
            stopTransfer(abort: false)
        case .disconnecting:
            bleManager.hasDisconnectedForUpdate = true
        case .aborted:
            log("DFU upload successfully aborted", caller: "DFUUpdater", target: .dfu)
        default:
            break
        }
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        stopTransfer(abort: false)
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = Double(progress)
	}
	
	func logWith(_ level: LogLevel, message: String) {
        log("DFU log: \(message)", type: .info, caller: "DFUUpdater", target: .dfu)
	}
}
