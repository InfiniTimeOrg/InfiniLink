//
//  DFU.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import NordicDFU
import SwiftUI

class DFU_Updater: ObservableObject, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
	
	static let shared = DFU_Updater()
	
	private var url: URL = URL(fileURLWithPath: "")
	var bleManager: BLEManager = BLEManager.shared
	var dfuController: DFUServiceController!
	
	@Published var dfuState: String = ""
	@Published var transferCompleted = false
	@Published var percentComplete: Double = 0
	
	@Published var firmwareFilename = ""
    @Published var resourceFilename = ""
	@Published var firmwareSelected: Bool = false
	public var local = true
	public var firmwareURL: URL!

    @AppStorage("lockNavigation") var lockNavigation = false
	
	func transfer() {
		guard let url = firmwareURL else {return}
		guard url.startAccessingSecurityScopedResource() else { return }
		guard let selectedFirmware = try? DFUFirmware(urlToZipFile:url) else {
			DebugLogManager.shared.debug(error: "Error loading firmware file. Is the file a DFU zip?", log: .dfu, date: Date())
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
			DebugLogManager.shared.debug(error: "Error loading firmware file. Is the file a DFU zip?", log: .dfu, date: Date())
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
	}
	
	func stopTransfer() {
		if dfuController != nil {
			_ = dfuController.abort()
			dfuController = nil
		}
		dfuState = ""
		transferCompleted = false
        lockNavigation = false
		percentComplete = 0
	}
	
	// stubs added automatically.
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state.description
		if state.rawValue == 6 {
			transferCompleted = true
            lockNavigation = false
			dfuController = nil
			percentComplete = 0
		}
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		DebugLogManager.shared.debug(error: "DFU Error: \(message)", log: .dfu, date: Date())
		
		dfuController = nil
		transferCompleted = false
		percentComplete = 0
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = Double(progress)
	}
	
	func logWith(_ level: LogLevel, message: String) {
		let level = level.name()
		DebugLogManager.shared.debug(error: "DFU \(level): \(message)", log: .dfu, date: nil)
	}
}
