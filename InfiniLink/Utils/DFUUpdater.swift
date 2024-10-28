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
	
	var bleManager: BLEManager = BLEManager.shared
	var dfuController: DFUServiceController!
	
	@Published var dfuState: String = ""
    @Published var transferCompleted = false
	@Published var isUpdating = false
	@Published var percentComplete: Double = 0
	
	@Published var firmwareFilename = ""
    @Published var resourceFilename = ""
	@Published var firmwareSelected: Bool = false
    @Published var local = true
    @Published var firmwareURL: URL!
	
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
        // initiator.packetReceiptNotificationParameter = N // default is 12
        initiator.logger = self // - to get log info
        initiator.delegate = self // - to be informed about current state and errors
        initiator.progressDelegate = self // - to show progress bar
        // initiator.peripheralSelector = ... // the default selector is used
        if bleManager.infiniTime != nil {
            dfuController = initiator.start(target: bleManager.infiniTime)
        }
        url.stopAccessingSecurityScopedResource()
    }
	
	func downloadTransfer() {
		guard let selectedFirmware = try? DFUFirmware(urlToZipFile: firmwareURL) else {
            print("Error loading firmware")
			return
		}
        
        self.isUpdating = true
	
		let initiator = DFUServiceInitiator().with(firmware: selectedFirmware)

        // Optional:
		// initiator.forceDfu = true/false // default false
		// initiator.packetReceiptNotificationParameter = N // default is 12
		initiator.logger = self // - to get log info
		initiator.delegate = self // - to be informed about current state and errors
		initiator.progressDelegate = self // - to show progress bar
		// initiator.peripheralSelector = ... // the default selector is used
		if bleManager.infiniTime != nil {
			dfuController = initiator.start(target: bleManager.infiniTime)
		}
	}
	
	func stopTransfer() {
		if dfuController != nil {
			_ = dfuController.abort()
			dfuController = nil
		}
		dfuState = ""
		transferCompleted = false
		percentComplete = 0
	}
	
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state.description
        // TODO: handle more cases
		if state.rawValue == 6 {
			transferCompleted = true
            firmwareFilename = ""
            resourceFilename = ""
            firmwareSelected = false
            isUpdating = true
			dfuController = nil
			percentComplete = 0
		}
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		dfuController = nil
		transferCompleted = false
		percentComplete = 0
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = Double(progress)
	}
	
	func logWith(_ level: LogLevel, message: String) {
		let level = level.name()
		
        print("DFU log level: ", level)
	}
}
