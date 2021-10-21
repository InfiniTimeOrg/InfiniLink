//
//  DebugUtilities.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/14/21.
//  
//
    

import Foundation

// MARK: logging



class DebugLogManager: ObservableObject {
	
	@Published var logFiles = LogFiles()
	static let shared = DebugLogManager()
	
	struct LogEntry {
		let id = UUID()
		let date: String
		let message: String
		let log: DebugLog
	}

	struct LogFiles {
		var bleLogEntries: [LogEntry] = []
		var dfuLogEntries: [LogEntry] = []
		var appLogEntries: [LogEntry] = []
	}


	enum DebugLog {
		case dfu
		case ble
		case app
	}
	
	func debug(error: String, log: DebugLog, date: Date! = nil) {
		let settings = UserDefaults.standard
		let debugMode = settings.object(forKey: "debugMode") as? Bool ?? false
		if debugMode {
			var dateString = ""
			if date != nil {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "MMM d, HH:mm"
				dateString = dateFormatter.string(from: date)
			}
			
			let logEntry = LogEntry(date: dateString, message: error, log: log)
			DebugLogManager.shared.addLogEntry(entry: logEntry)
		}
	}
	
	func addLogEntry(entry: LogEntry) {
		
		switch entry.log {
		case .dfu:
			logFiles.dfuLogEntries.append(entry)
		case .ble:
			logFiles.bleLogEntries.append(entry)
		case.app:
			logFiles.appLogEntries.append(entry)
		}
	}
}
