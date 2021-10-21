//
//  DebugViewApp.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/29/21.
//  
//
    

import SwiftUI

struct DebugViewApp: View {
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var logManager = DebugLogManager.shared
	
	var body: some View {
		VStack {
			List {
				ForEach(0..<logManager.logFiles.appLogEntries.count, id: \.self) { entry in
					Text(
						// if a date is included, prepend '[date] -', otherwise start with empty string
						(logManager.logFiles.appLogEntries[entry].date.isEmpty ? "" : logManager.logFiles.appLogEntries[entry].date + " - ") + logManager.logFiles.appLogEntries[entry].message
					)
				}
			}
		}
	}
}

