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
	@Published var heartBPM: String!									// published var to communicate the HRM data to the UI. I don't know enough about Swift to know if this is a bad idea.
	@Published var batteryLevel: String!								// Same as heartBPM but for battery data

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
		heartBPM = "Reading"
		batteryLevel = "Reading"
	}
	
	func startScanning() {
		print("startScanning")
		myCentral.scanForPeripherals(withServices: nil, options: nil)
		isScanning = true
		peripherals = [Peripheral]()
		peripheralDictionary = [:]
	}
	
	func stopScanning() {
		print("stopScanning")
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

extension BLEManager: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else { return }

		for service in services {
			peripheral.discoverCharacteristics(nil, for:service)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else { return }
		
		for characteristic in characteristics {
			if characteristic.properties.contains(.read) {
				peripheral.readValue(for: characteristic)
			}
			
			// subscribe to all values that can be subscribed to.
			// TODO: separate this out and subscribe individually for each service in a separate .swift document so this isn't so monolithic
			if characteristic.properties.contains(.notify) {
				switch characteristic.uuid {
				case musicControlCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
					print("subscribed to", characteristic.uuid)
				case hrmCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
					print("subscribed to", characteristic.uuid)
				case batCBUUID:
					peripheral.setNotifyValue(true, for: characteristic)
					print("subscribed to", characteristic.uuid)
				default:
					break
				}
				peripheral.setNotifyValue(true, for: characteristic)
			}
			
			if characteristic.properties.contains(.write) {
				if characteristic.uuid == notifyCBUUID {
					// I'm sure there's a less clunky way to grab the full characteristic for the sendNotification() function, but this works fine for now
					notifyCharacteristic = characteristic
					sendNotification(notification: "iOS Connected!")
				}
			}
		}
	}
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		switch characteristic.uuid {
		case musicControlCBUUID:
			// listen for the music controller notifications
			musicChars.control = characteristic
			let musicControl = [UInt8](characteristic.value!)
			controlMusic(controlNumber: Int(musicControl[0]))
			
		case musicTrackCBUUID:
			// select track characteristic for writing to music app
			musicChars.track = characteristic
			
		case musicArtistCBUUID:
			// select artist characteristic for writing to music app
			musicChars.artist = characteristic
			
		case hrmCBUUID:
			// read heart rate hex, convert to decimal
			let bpm = heartRate(from: characteristic)
			heartBPM = String(bpm)
			
		case batCBUUID:
			// read battery hex data, convert it to decimal
			let batData = [UInt8](characteristic.value!)
			batteryLevel = String(batData[0])
			
		case timeCBUUID:
			// convert string with hex value of time to actual hex data, then write to PineTime
			peripheral.writeValue(currentTime().hexData, for: characteristic, type: .withResponse)
	
		default:
			break
		}
	}
	
	// this function converts string to ascii and writes to the selected characteristic. Used for notifications and music app
	func writeASCIIToPineTime(message: String, characteristic: CBCharacteristic) {
		let writeData = message.data(using: .ascii)!
		infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
	}
	
	
	// function to translate heart rate to decimal, copied straight up from this tut: https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-014
	private func heartRate(from characteristic: CBCharacteristic) -> Int {
		guard let characteristicData = characteristic.value else { return -1 }
		let byteArray = [UInt8](characteristicData)

		let firstBitValue = byteArray[0] & 0x01
		if firstBitValue == 0 {
			// Heart Rate Value Format is in the 2nd byte
			return Int(byteArray[1])
		} else {
			// Heart Rate Value Format is in the 2nd and 3rd bytes
			return (Int(byteArray[1]) << 8) + Int(byteArray[2])
		}
	}
	
	// this function pulls date from phone, shuffles it into the correct order, and then hex-encodes it to a format that InfiniTime can understand
	private func currentTime() -> String {
		let now = Date() // current time
		
		// formatting setup for the date, not including the year because we have to reformat the year hex to match what the PT expects
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM dd H m s e SSSS"
		
		// prepare formatting for year
		let yearFormatter = DateFormatter()
		yearFormatter.dateFormat = "y"
		let yearString = yearFormatter.string(from: now)
		let intYear = Int(yearString)
		
		// convert year string to hex-encoded string. conditionally prepend 0 in case by some miracle this application and your watch is still functional in the year 4096
		var hexYear = String (format: "%02X", intYear!)
		if hexYear.count == 3 {
			hexYear.insert("0", at: hexYear.startIndex)
		}
		
		// infinitime (and BLE in general? I dunno...) requires the MSB first, so we have to switch the year from XXYY to YYXX
		var revYearChars = hexYear.suffix(2)
		revYearChars += hexYear.prefix(2)
		
		var fullDateString = String(revYearChars)
		
		let dateString = dateFormatter.string(from: now)
		let dateParts = dateString.components(separatedBy: " ")
		
		// convert the rest of the date parts to hex, and append them to the date string
		
		for part in dateParts {
			let intPart = Int(part)
			let hex = String(format: "%02X", intPart!)
			fullDateString.append(hex)
		}
		
		// print(fullDateString) // debug
		return fullDateString
	}
}
