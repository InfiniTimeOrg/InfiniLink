//
//  DebugViewBLE.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/29/21.
//  
//
    

import Foundation
import SwiftUI

struct DebugViewBLE: View {
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var logManager = DebugLogManager.shared
	
	var body: some View {
		VStack {
			List {
				ForEach(0..<logManager.logFiles.bleLogEntries.count, id: \.self) { entry in
					Text(logManager.logFiles.bleLogEntries[entry].date + " - " + (logManager.logFiles.bleLogEntries[entry].message.isEmpty ? logManager.logFiles.bleLogEntries[entry].additionalInfo : logManager.logFiles.bleLogEntries[entry].message))
				}
			}
		}
	}
}
