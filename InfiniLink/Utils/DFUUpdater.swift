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
    @Published var isUpdating = false
	@Published var isUpdatingResources = false
	@Published var percentComplete: Double = 0
	
	@Published var firmwareFilename = ""
    @Published var resourceFilename = ""
	@Published var firmwareSelected: Bool = false
    @Published var local = true
    @Published var firmwareURL: URL!
    @Published var resourceURL: URL!
    
    @AppStorage("updateResourcesWithFirmware") var updateResourcesWithFirmware = true
	
    func transfer() {
        guard let url = firmwareURL else {return}
        guard url.startAccessingSecurityScopedResource() else { return }
        guard let selectedFirmware = try? DFUFirmware(urlToZipFile:url) else {
            print("Error loading firmware file.")
            return
        }
        let initiator = DFUServiceInitiator().with(firmware: selectedFirmware)
        
        // Optional:
        // initiator.forceDfu = true/false // default false
        initiator.packetReceiptNotificationParameter = 20
        initiator.logger = self // - to get log info
        initiator.delegate = self // - to be informed about current state and errors
        initiator.progressDelegate = self // - to show progress bar
        // initiator.peripheralSelector = ... // the default selector is used
        if bleManager.infiniTime != nil {
            dfuController = initiator.start(target: bleManager.infiniTime)
        }
        url.stopAccessingSecurityScopedResource()
    }
    
    func updateFirmware() {
        guard let selectedFirmware = try? DFUFirmware(urlToZipFile: firmwareURL) else {
            print("Error loading firmware")
            return
        }
        
        self.isUpdating = true
        
        let initiator = DFUServiceInitiator().with(firmware: selectedFirmware)
        
        // Optional:
        // initiator.forceDfu = true/false // default false
        initiator.packetReceiptNotificationParameter = 20
        initiator.logger = self // - to get log info
        initiator.delegate = self // - to be informed about current state and errors
        initiator.progressDelegate = self // - to show progress bar
        // initiator.peripheralSelector = ... // the default selector is used
        if bleManager.infiniTime != nil {
            dfuController = initiator.start(target: bleManager.infiniTime)
        }
    }
	
	func downloadTransfer() {
        if resourceURL != nil && !local {
            isUpdatingResources = true
            dfuState = "Updating resources"
            
            BLEFSHandler.shared.downloadTransfer { [self] in
                isUpdatingResources = false
                updateFirmware()
            }
        } else {
            updateFirmware()
        }
	}
	
	func stopTransfer() {
		if dfuController != nil {
			_ = dfuController.abort()
			dfuController = nil
		}
		dfuState = ""
		transferCompleted = false
        isUpdating = false
		percentComplete = 0
	}
	
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state.description
        
        if state == .completed {
            transferCompleted = true
            isUpdating = false
            firmwareFilename = ""
            resourceFilename = ""
            firmwareSelected = false
            
            downloadManager.updateStarted = false
		}
        
        dfuController = nil
        percentComplete = 0
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        self.stopTransfer()
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = Double(progress)
	}
	
	func logWith(_ level: LogLevel, message: String) {
        print("DFU log level: \(level.name()), message: \(message)")
	}
}
