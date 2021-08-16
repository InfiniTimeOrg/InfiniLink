//
//  BLEManager.swift
//  Infini-iOS
//
//  Created by xan-m on 8/3/21.
//

import Foundation
import CoreBluetooth


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
	
	var myCentral: CBCentralManager!
	var notifyCharacteristic: CBCharacteristic!
	
	struct musicCharacteristics {
		var control: CBCharacteristic!
		var track: CBCharacteristic!
		var artist: CBCharacteristic!
	}
	
	@Published var musicChars = musicCharacteristics()
	
	// UI flag variables
	@Published var isSwitchedOn = false									// for now this is used to display if bluetooth is on in the main app screen. maybe an alert in the future?
	@Published var isScanning = false									// another UI flag. Probably not necessary for anything but debugging. I dunno maybe a little swirly animation or something could be triggered by this
	@Published var isConnectedToPinetime = false						// another flag published to update UI stuff. Can probably be implemented better in the future
	@Published var heartBPM: String = "Disconnected"					// published var to communicate the HRM data to the UI.
	@Published var batteryLevel: String = "Disconnected"				// Same as heartBPM but for battery data
	@Published var firmwareVersion: String = "Disconnected"

	// Selecting and connecting variables
	@Published var peripherals = [Peripheral]() 						// used to print human-readable device names to UI in selection process
	@Published var deviceToConnect: Int!								// When the user selects a device from the UI, that peripheral's ID goes in this var, which is passed to the peripheralDictionary
	@Published var peripheralDictionary: [Int: CBPeripheral] = [:] 		// this is the dictionary that relates human-readable peripheral names to the CBPeripheral class that CoreBluetooth actually interacts with
	@Published var infiniTime: CBPeripheral!							// variable to save the CBPeripheral that you're connecting to
	
	// declare some CBUUIDs for easier reference
	let hrmCBUUID = CBUUID(string: "2A37")
	let batCBUUID = CBUUID(string: "2A19")
	let timeCBUUID = CBUUID(string: "2A2B")
	let notifyCBUUID = CBUUID(string: "2A46")
	let firmwareCBUUID = CBUUID(string: "2A26")
	let musicControlCBUUID = CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")
	let musicTrackCBUUID = CBUUID(string: "00000004-78FC-48FE-8E23-433B3A1942D0")
	let musicArtistCBUUID = CBUUID(string: "00000003-78FC-48FE-8E23-433B3A1942D0")
	
	struct Peripheral: Identifiable {
		let id: Int
		let name: String
		let rssi: Int
		let peripheralHash: Int
	}
	
	override init() {
		super.init()

		myCentral = CBCentralManager(delegate: self, queue: nil)
		myCentral.delegate = self
		
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
		}
	}
	
	func connect(peripheral: CBPeripheral) {
		// Still blocking connections to anything not named "InfiniTime" until I can set up a proper way to test other devices
		
		if peripheral.name == "InfiniTime" {
			self.myCentral.stopScan()
			isScanning = false
			
			self.infiniTime = peripheral
			infiniTime.delegate = self
			self.myCentral.connect(peripheral, options: nil)
			
			isConnectedToPinetime = true
		}
	}
		
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		var peripheralName: String!
		
		if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
			peripheralName = name
		}
		else {
			peripheralName = "Unknown"
		}
		
		let newPeripheral = Peripheral(id: peripheralDictionary.count, name: peripheralName, rssi: RSSI.intValue, peripheralHash: peripheral.hash)

		// compare peripheral hashes to make sure we're only adding each device once -- super helpful if you have a very noisy BLE advertiser nearby!
		// this hash value is functional only for separating devices during this search, and is not at all guaranteed to be a persistent value. Probably not to be trusted for long-term autoconnect persistence. So far, I have gotten the same value for my PineTime every time I run the app, but based on the Apple docs this is not a guarantee.
		if !peripherals.contains(where: {$0.peripheralHash == newPeripheral.peripheralHash}) {
			// I think there's probably a way to get rid of this array someday, but for now it's useful for displaying the device names. You cant have a Peripheral struct as a key in the peripheralDictionary, so there has to be some way to pass the names to the UI, and the peripherals array seems like it.
			peripherals.append(newPeripheral)
			peripheralDictionary[newPeripheral.peripheralHash] = peripheral
			
			print(newPeripheral, "added to list")
		}
	}
	
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		self.infiniTime.discoverServices(nil)
	}
	
	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		isConnectedToPinetime = false
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

