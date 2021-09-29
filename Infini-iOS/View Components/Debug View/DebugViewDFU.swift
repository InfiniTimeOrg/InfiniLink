//
//  DebugViewDFU.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/29/21.
//  
//
    

import SwiftUI

struct DebugViewDFU: View {
	@ObservedObject var bleManager = BLEManager.shared
	@ObservedObject var logManager = DebugLogManager.shared
	
	var body: some View {
		VStack {
			List {
				ForEach(0..<logManager.logFiles.dfuLogEntries.count, id: \.self) { entry in
					Text(logManager.logFiles.dfuLogEntries[entry].date + " - " + logManager.logFiles.dfuLogEntries[entry].message)
				}
			}
		}
	}
}

