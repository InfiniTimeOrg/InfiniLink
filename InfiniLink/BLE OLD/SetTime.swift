//
//  SetTime.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/29/21.
//  
//
    

import Foundation

class SetTime {
	
	var logManager = DebugLogManager.shared
	
	enum SetTimeError: Error {
		case nilValue
	}
		
	// this function pulls date from phone, shuffles it into the correct order, and then hex-encodes it to a format that InfiniTime can understand
	func currentTime() throws -> String {
		let now = Date() // current time
		
		// formatting setup for the date, not including the year because we have to reformat the year hex to match what the PT expects
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM dd H m s e SSSS"
		dateFormatter.isLenient = false
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		
		// prepare formatting for year
		let yearFormatter = DateFormatter()
		yearFormatter.dateFormat = "yyyy"
		yearFormatter.isLenient = false
		yearFormatter.locale = Locale(identifier: "en_US_POSIX")
		
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
		
		var debugString = "Date components array: "
		
		// convert the rest of the date parts to hex, and append them to the date string
		for part in dateString.components(separatedBy: " ") {
			debugString.append(String("\(part), "))
			guard let intPart = Int(part) else {
				logManager.debug(error: "Failed to set date!", log: .app, date: Date())
				logManager.debug(error: "Full date string: \(dateString)", log: .app)
				logManager.debug(error: "'\(part)' was unable to be converted to an Integer", log: .app)
				throw SetTimeError.nilValue
			}
			let hex = String(format: "%02X", intPart)
			fullDateString.append(hex)
		}
		return fullDateString
	}
}
