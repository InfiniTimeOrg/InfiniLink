//
//  BLEManagerExtensions.swift
//  Infini-iOS
//
//  Created by xan-m on 8/15/21.
//  
//
    

import Foundation
import CoreBluetooth

extension BLEManager {
	
	// this function converts string to ascii and writes to the selected characteristic. Used for notifications and music app
	func writeASCIIToPineTime(message: String, characteristic: CBCharacteristic) {
		let writeData = message.data(using: .ascii)!
		infiniTime.writeValue(writeData, for: characteristic, type: .withResponse)
	}
	
	
	// function to translate heart rate to decimal, copied straight up from this tut: https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-014
	func heartRate(from characteristic: CBCharacteristic) -> Int {
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
	func currentTime() -> String {
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
