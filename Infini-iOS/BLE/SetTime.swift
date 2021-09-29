//
//  SetTime.swift
//  Infini-iOS
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
		
		let dateString = dateFormatter.string(from: now) + "x"
		
		var debugString = "Date components array: "
		
		// convert the rest of the date parts to hex, and append them to the date string
		for part in dateString.components(separatedBy: " ") {
			debugString.append(String("\(part), "))
			guard let intPart = Int(part) else {
				logManager.debug(error: nil, log: .app, additionalInfo: "Failed to set date!", date: Date())
				logManager.debug(error: nil, log: .app, additionalInfo: "Full date string: \(dateString)")
				logManager.debug(error: nil, log: .app, additionalInfo: debugString)
				if part.isEmpty {
					logManager.debug(error: nil, log: .app, additionalInfo: "Tried to convert a nil value")
				} else {
					logManager.debug(error: nil, log: .app, additionalInfo: "'\(part)' was unable to be converted to an Integer")
				}
				throw SetTimeError.nilValue
			}
			let hex = String(format: "%02X", intPart)
			fullDateString.append(hex)

		}
		
		// print(fullDateString) // debug
		return fullDateString
	}
}
