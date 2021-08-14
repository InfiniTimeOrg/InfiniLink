//
//  DFU.swift
//  Infini-iOS
//
//  Created by xan-m on 8/11/21.
//

import Foundation
import NordicDFU

class DFU_Updater: ObservableObject, DFUServiceDelegate, DFUProgressDelegate, LoggerDelegate {
	
	private var url: URL = URL(fileURLWithPath: "")
	var bleManager: BLEManager
	var deviceToUpgrade: BLEManager.Peripheral!
	
	@Published var dfuState: DFUState = DFUState.starting
	@Published var dfuStatus: String = ""
	@Published var percentComplete: Int = 0
	
	init(ble: BLEManager){
		bleManager = ble
	}
	
	func prepare(location: URL, device: BLEManager) {
		url = location
		bleManager = device
	}
	
	func transfer() {
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

		_ = initiator.start(target: bleManager.infiniTime)
		url.stopAccessingSecurityScopedResource()
	}
	
	
	// stubs added automatically.
	func dfuStateDidChange(to state: DFUState) {
		dfuState = state
		print(state)
	}
	
	func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
		print("DFU Error:", error)
	}
	
	func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
		percentComplete = progress
	}
	
	func logWith(_ level: LogLevel, message: String) {
	}

	
}
