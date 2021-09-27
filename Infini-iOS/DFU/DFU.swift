//
//  DFU.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import NordicDFU

class DFU_Updater: ObservableObject, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate  {
	
	static let shared = DFU_Updater()
	
	private var url: URL = URL(fileURLWithPath: "")
	var bleManager: BLEManager = BLEManager.shared
	var dfuController: DFUServiceController!
	
	@Published var dfuState: String = ""
	@Published var transferFailed = false
	@Published var transferCompleted = false
	@Published var percentComplete: Double = 0
	
	@Published var firmwareFilename = ""
	@Published var firmwareSelected: Bool = false
	public var local = true
	public var firmwareURL: URL!

	
//	func prepare(location: URL, device: BLEManager) {
//		url = location
//		bleManager = device
//	}
	
	func transfer() {
		guard let url = firmwareURL else {return}
		guard url.startAccessingSecurityScopedResource() else { return }
		guard let selectedFirmware = DFUFirmware(urlToZipFile:url) else { return }
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
		print("transfer function:")

		
		guard let selectedFirmware = DFUFirmware(urlToZipFile: firmwareURL) else { print("failed to load file"); return }
	
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
		}
	}
	
	// stubs added automatically.
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state.description()
		print(dfuState)
		if state.rawValue == 6 {
			transferCompleted = true
			print(transferCompleted)
		}
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		print("DFU Error:", message)
		
		dfuController = nil
		transferFailed = true
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = Double(progress)
	}
	
	func logWith(_ level: LogLevel, message: String) {
		//print("DFU \(level.name()): \(message)")
	}

	
}
