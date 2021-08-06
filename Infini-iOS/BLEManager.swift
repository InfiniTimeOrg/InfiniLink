//
//  BLEManager.swift
//  Infini-iOS
//
//  Created by xan-m on 8/3/21.
//

import Foundation
import CoreBluetooth

struct Peripheral: Identifiable {
	let id: Int
	let name: String
	let rssi: Int
}

// declare some CBUUIDs for easier reference
let hrmCBUUID = CBUUID(string: "2A37")
let batCBUUID = CBUUID(string: "2A19")
let timeCBUUID = CBUUID(string: "2A2B")
let notifyCBUUID = CBUUID(string: "2A46")
let musicControlCBUUID = CBUUID(string: "00000001-78FC-48FE-8E23-433B3A1942D0")

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
	
	var myCentral: CBCentralManager!
	var notifyCharacteristic: CBCharacteristic!
	
	@Published var isSwitchedOn = false
	@Published var peripherals = [Peripheral]()
	@Published var peripheralDictionary: [Int: CBPeripheral] = [:]
	@Published var isConnectedToPinetime = false
	@Published var infiniTime: CBPeripheral!
	@Published var heartBPM: String!
	@Published var batteryLevel: String!
	@Published var isScanning = false
	@Published var deviceToConnect: Int!
	
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
		// working on adding user choice, but still blocking anything but InfiniTime until I can set up a proper way to test it, because it might crash everything?
		
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
		// scan BLE devices, looking for any named InfiniTime, and then automatically connect to InfiniTime
		// I know this sucks for anyone who has more than one watch, a dev/sealed pair, waspOS, etc. I'll open this up when I've got the core functionality for InfiniTime locked in
		
		var peripheralName: String! // ** not necessary without below scan list thing
		
		if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
			peripheralName = name
		}
		else {
			peripheralName = "Unknown"
		}
		
		let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
		print(newPeripheral)
		
		// ************************* remove if statement from code! but holy fuck this TV is the noisiest BLE advertiser in the world what the actual fuck *****************************
		
		if newPeripheral.name != "[TV] Samsung 8 Series (50)" {
			peripherals.append(newPeripheral)
			peripheralDictionary[newPeripheral.id] = peripheral
		}
		
		/*
		
		this can probably be a function

		if let pname = peripheral.name {
			if pname == "InfiniTime" {
				self.myCentral.stopScan()
				isScanning = false
				
				self.infiniTime = peripheral
				infiniTime.delegate = self
				self.myCentral.connect(peripheral, options: nil)
				
				isConnectedToPinetime = true
			}
		}
		
		*/

		/*
		
		********
		scan for all nearby BLE devices -- this was part of one of the tuts I was following. For now I'm just going to keep the app tightly coupled to PineTimes running Infinitime to reduce complexity for initial development. This code will be useful if it turns out this app is functional with other similar watches/waspOS/etc.
		********
		
		var peripheralName: String! ** not necessary without below scan list thing
		
		if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
			peripheralName = name
		}
		else {
			peripheralName = "Unknown"
		}
		   
		let newPeripheral = Peripheral(id: peripherals.count, name: peripheralName, rssi: RSSI.intValue)
		print(newPeripheral)
		peripherals.append(newPeripheral)
		
		*/
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
			
			// subscribe to values that can be subscribed to
			if characteristic.properties.contains(.notify) {
				peripheral.setNotifyValue(true, for: characteristic)
				// print(characteristic.uuid, "can notify") // debug
			}
			
			if characteristic.properties.contains(.write) {
				//print(characteristic.uuid, "is writable") // debug
				if characteristic.uuid == notifyCBUUID {
					notifyCharacteristic = characteristic
				}
			}
		}
	}
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		switch characteristic.uuid {
		case musicControlCBUUID:
			// listen for the music controller notifications
			let musicControl = [UInt8](characteristic.value!)
			let musicNumber = String(musicControl[0])
			// for now just print to console, but I am getting the numbers as a string here, and hopefully I can use that to control music apps soon
			print(musicNumber) // debug
		
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

	func sendNotification(notification: String) {
		let paddedNotification = "   " + notification // I'm pretty sure this is due to a lack of understanding on my part of the notification protocol, but sending ascii text as a notification eats the first 3 characters, so add 3 spaces here to absorb that
		let notificationData = paddedNotification.data(using: .ascii)!
		if notifyCharacteristic != nil {
			infiniTime.writeValue(notificationData, for: notifyCharacteristic, type: .withResponse)
		}
	}
	
	// function to translate heart rate to decimal
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
	
	// this function pulls date from phone, shuffles it around, and then hex-encodes it to a format that InfiniTime can understand
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
