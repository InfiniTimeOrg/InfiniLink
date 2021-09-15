//
//  DebugUtilities.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/14/21.
//  
//
    

import Foundation

// MARK: logging

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

var logFiles = LogFiles()

enum DebugLog {
	case dfu
	case ble
	case app
}

class BLELogs: ObservableObject {
	
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
