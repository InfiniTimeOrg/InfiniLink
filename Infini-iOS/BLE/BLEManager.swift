//
//  BLEManager.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/3/21.
//

import Foundation
import CoreBluetooth
import SwiftUICharts


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
	
	var myCentral: CBCentralManager!
	var notifyCharacteristic: CBCharacteristic!
	
	struct musicCharacteristics {
		var control: CBCharacteristic!
		var track: CBCharacteristic!
		var artist: CBCharacteristic!
	}
	
	struct Peripheral: Identifiable {
		let id: Int
		let name: String
		let rssi: Int
		let peripheralHash: Int
		let deviceUUID: CBUUID
	}
	
	@Published var musicChars = musicCharacteristics()
	
	let settings = UserDefaults.standard
	
	// UI flag variables
	@Published var isSwitchedOn = false									// for now this is used to display if bluetooth is on in the main app screen. maybe an alert in the future?
	@Published var isScanning = false									// another UI flag. Probably not necessary for anything but debugging. I dunno maybe a little swirly animation or something could be triggered by this
	@Published var isConnectedToPinetime = false						// another flag published to update UI stuff. Can probably be implemented better in the future
	@Published var heartBPM: Double = 0									// published var to communicate the HRM data to the UI.
	@Published var batteryLevel: Double = 0								// Same as heartBPM but for battery data
	@Published var hrmChartDataPoints: [LineChartDataPoint] = []
	@Published var batChartDataPoints: [LineChartDataPoint] = []
	@Published var firmwareVersion: String = "Disconnected"
	@Published var setTimeError = false
	@Published var blePermissions: Bool!

	// Selecting and connecting variables
	@Published var peripherals = [Peripheral]() 						// used to print human-readable device names to UI in selection process
	@Published var deviceToConnect: Int!								// When the user selects a device from the UI, that peripheral's ID goes in this var, which is passed to the peripheralDictionary
	@Published var peripheralDictionary: [Int: CBPeripheral] = [:] 		// this is the dictionary that relates human-readable peripheral names to the CBPeripheral class that CoreBluetooth actually interacts with
	@Published var infiniTime: CBPeripheral!							// variable to save the CBPeripheral that you're connecting to
	@Published var autoconnectPeripheral: CBPeripheral!
	@Published var setAutoconnectUUID: String = ""							// placeholder for now while I figure out how to save the whole device in UserDefaults to save "favorite" devices
	
	@Published var bleLogger = BLELogs() // MARK: logging
	
	var firstConnect: Bool = true										// makes iOS connected message only show up on first connect, not if device drops connection and reconnects
	
	// declare some CBUUIDs for easier reference
	let hrmCBUUID = CBUUID(string: "2A37")
	let batCBUUID = CBUUID(string: "2A19")
	let timeCBUUID = CBUUID(string: "2A2B")
	let notifyCBUUID = CBUUID(string: "2A46")
	let firmwareCBUUID = CBUUID(string: "2A26")
	let musicControlCBUUID = CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")
	let musicTrackCBUUID = CBUUID(string: "00000004-78FC-48FE-8E23-433B3A1942D0")
	let musicArtistCBUUID = CBUUID(string: "00000003-78FC-48FE-8E23-433B3A1942D0")
	

	
	override init() {
		super.init()

		myCentral = CBCentralManager(delegate: self, queue: nil)
		myCentral.delegate = self
		if myCentral.state == .unauthorized {
			blePermissions = false
		} else {
			blePermissions = true
		}
	}
	
	func startScanning() {
		myCentral.scanForPeripherals(withServices: nil, options: nil)
		isScanning = true
		peripherals = [Peripheral]()
		peripheralDictionary = [:]
	}
	
	func stopScanning() {
		myCentral.stopScan()
		isScanning = false
	}
	
	func disconnect(){
		if infiniTime != nil {
			myCentral.cancelPeripheralConnection(infiniTime)
			firstConnect = true
			isConnectedToPinetime = false
		}
	}
	
	// MARK: logging
	func debug(error: Error?) {
		let settings = UserDefaults.standard
		let debugMode = settings.object(forKey: "debugMode") as? Bool ?? false
		if debugMode {
			print(error.debugDescription)
			let date = Date()
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "MMM d, HH:mm"
			
			let logEntry = LogEntry(date: dateFormatter.string(from: date), message: error?.localizedDescription ?? "", log: DebugLog.ble)
			bleLogger.addLogEntry(entry: logEntry)
		}
	}
	
	func connect(peripheral: CBPeripheral) {
		// Still blocking connections to anything not named "InfiniTime" until I can set up a proper way to test other devices
		
		if peripheral.name == "InfiniTime" || peripheral.name == "Pinetime-JF" {
			self.myCentral.stopScan()
			isScanning = false
			
			self.infiniTime = peripheral
			infiniTime.delegate = self
			self.myCentral.connect(peripheral, options: nil)
			
			setAutoconnectUUID = peripheral.identifier.uuidString
			isConnectedToPinetime = true
		}
	}
		
	

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		var peripheralName: String!
		// TODO: Recreate the process below.
		/*
			- the hash I'm using is only unique between PineTimes because the peripheral struct includes an incrementing ID number that's part of the hash.
				- this works for getting more than one PT in the menu, but is obviously a drag because it's not at all guaranteed to be persistent
			- there's some stuff happening here that doesn't need to happen - ex. there's an array and a dictionary doing basically the same thing?
			- I mistakenly was under the impression that the UUID was generated by InfiniTime and was probably the same across all instances of InfiniTime, but it seems like that's incorrect!
		*/
		
		if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
			peripheralName = name
			let devUUIDString: String = peripheral.identifier.uuidString
			let devUUID: CBUUID = CBUUID(string: devUUIDString)
			let newPeripheral = Peripheral(id: peripheralDictionary.count, name: peripheralName, rssi: RSSI.intValue, peripheralHash: peripheral.hash, deviceUUID: devUUID)

			
			// handle autoconnect defaults
			let settings = UserDefaults.standard
			let autoconnect = settings.object(forKey: "autoconnect") as? Bool ?? true
			let autoconnectUUID = settings.object(forKey: "autoconnectUUID") as? String ?? ""
			
			if autoconnect && devUUIDString == autoconnectUUID {
				connect(peripheral: peripheral)
			}
			else {
				// compare peripheral hashes to make sure we're only adding each device once -- super helpful if you have a very noisy BLE advertiser nearby!
				if !peripherals.contains(where: {$0.deviceUUID == newPeripheral.deviceUUID}) {
					peripherals.append(newPeripheral)
					peripheralDictionary[newPeripheral.peripheralHash] = peripheral
				}
			}
		}
	}
	
	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		debug(error: error) // MARK: logging
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		self.infiniTime.discoverServices(nil)
	}
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		if error != nil {
			connect(peripheral: peripheral)
		}
		debug(error: error) // MARK: logging
	}
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		if central.state == .poweredOn {
			isSwitchedOn = true
		}
		else {
			isSwitchedOn = false
		}
	}
}

