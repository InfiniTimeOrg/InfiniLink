//
//  DebugView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 9/14/21.
//  
//
    

import Foundation
import SwiftUI

struct DebugView: View {
	@ObservedObject var pageSwitcher = PageSwitcher.shared
	@ObservedObject var logManager = DebugLogManager.shared
	@State var activeTab = 1
	
	func getLogsAndShare() {
		var items: String = """
"""
		switch activeTab {
		case 1:
			for entry in 0..<logManager.logFiles.bleLogEntries.count {
				items.append("\(logManager.logFiles.bleLogEntries[entry].date + " - " + logManager.logFiles.bleLogEntries[entry].message)\n")
			}
		case 2:
			for entry in 0..<logManager.logFiles.dfuLogEntries.count {
				items.append("\(logManager.logFiles.dfuLogEntries[entry].date + " - " + logManager.logFiles.dfuLogEntries[entry].message)\n")
			}
		case 3:
			for entry in 0..<logManager.logFiles.appLogEntries.count {
				items.append("\(logManager.logFiles.appLogEntries[entry].date + " - " + logManager.logFiles.appLogEntries[entry].message)\n")
			}
		default:
			return
		}
		shareApp(text: items)
	}
	
	func setPageTitle() -> String {
		switch self.activeTab{
		case 1:
			return "BLE Logs"
		case 2:
			return "DFU Logs"
		case 3:
			return "App Logs"
		default:
			return ""
		}
	}
	
	var body: some View {
		HStack {
			Text(setPageTitle())
				.font(.title)
				.padding()
			Spacer()
			Button {
				getLogsAndShare()
			} label: {
				Image(systemName: "square.and.arrow.up")
					.padding()
					.imageScale(.large)
			}
		}

		TabView (selection: $activeTab) {
			DebugViewBLE()
				.tabItem {
					Image(systemName: "radiowaves.right")
					Text("BLE")
				}
				.padding(.top)
				.tag(1)
			DebugViewDFU()
				.tabItem {
					Image(systemName: "arrow.up.doc")
					Text("DFU")
				}
				.padding(.top)
				.tag(2)
			DebugViewApp()
				.tabItem {
					Image(systemName: "ant")
					Text("App")
				}
				.padding(.top)
				.tag(3)
		}
	}
}
