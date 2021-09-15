//
//  DebugView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/14/21.
//  
//
    

import Foundation
import SwiftUI

// MARK: logging

struct DebugView: View {
	@EnvironmentObject var bleManager: BLEManager
	@EnvironmentObject var bleLogs: BLELogs
	
	
	var body: some View {
		VStack {
			Text("Debug Logs")
				.font(.largeTitle)
			List {
				ForEach(0..<logFiles.bleLogEntries.count, id: \.self) { entry in
					Text(logFiles.bleLogEntries[entry].date + " - " + logFiles.bleLogEntries[entry].message)
				}
			}
		}
	}
}
