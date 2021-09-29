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
	
	@discardableResult
	func share(excludedActivityTypes: [UIActivity.ActivityType]? = nil) -> Bool {
		var items: [String] = ["""
								"""]
		switch activeTab {
		case 1:
			for entry in 0..<logManager.logFiles.bleLogEntries.count {
				items[0].append("\(logManager.logFiles.bleLogEntries[entry].date + " - " + logManager.logFiles.bleLogEntries[entry].message)")
			}
		case 2:
			for entry in 0..<logManager.logFiles.dfuLogEntries.count {
				items[0].append("\(logManager.logFiles.dfuLogEntries[entry].date + " - " + logManager.logFiles.dfuLogEntries[entry].message)")
			}
		case 3:
			for entry in 0..<logManager.logFiles.appLogEntries.count {
				items[0].append("\(logManager.logFiles.appLogEntries[entry].date + " - " + logManager.logFiles.appLogEntries[entry].additionalInfo)\n")
			}
		default:
			return false
		}
		
		guard let source = UIApplication.shared.windows.last?.rootViewController else {
			return false
		}
		let vc = UIActivityViewController(
			activityItems: items,
			applicationActivities: nil
		)
		vc.excludedActivityTypes = excludedActivityTypes
		vc.popoverPresentationController?.sourceView = source.view
		source.present(vc, animated: true)
		return true
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
				share()
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
				.tag(1)
			DebugViewDFU()
				.tabItem {
					Image(systemName: "arrow.up.doc")
					Text("DFU")
				}
				.tag(2)
			DebugViewApp()
				.tabItem {
					Image(systemName: "ant")
					Text("App")
				}
				.tag(3)
		}
	}
}
