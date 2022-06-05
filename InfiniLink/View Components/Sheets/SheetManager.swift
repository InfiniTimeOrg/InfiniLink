//
//  SheetManager.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/29/21.
//  
//
    

import Foundation
import SwiftUI

enum SheetSelection {
	case onboarding
	case connect
	case notification
	case whatsNew
	case chartSettings
	case stepSettings
}

class SheetManager: ObservableObject {
	static let shared = SheetManager()
	
	@Published var showSheet: Bool = false
	@Published var sheetSelection: SheetSelection = .connect
	@Published var upToDate: Bool = false
	
	private var whatsNew: Bool = true
	
	let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
	var defaults = UserDefaults.standard
	
	func showWhatsNew () -> Bool {
		if !whatsNew {
			return false
		} else {
			var showSheet = false
			let lastVersion = defaults.value(forKey: "lastVersion") as? String ?? "0.0.0"
			let comparison = currentVersion.compare(lastVersion, options: .numeric)
			if comparison == .orderedDescending {
				showSheet = true
			}
			defaults.set(currentVersion, forKey: "lastVersion")
			whatsNew = false
			
			return showSheet
		}
	}
	
	func setNextSheet(autoconnect: Bool, autoconnectUUID: String) {
		let onboarding = defaults.value(forKey: "onboarding")
		if onboarding == nil {
			SheetManager.shared.sheetSelection = .onboarding
			SheetManager.shared.showSheet = true
		} else if SheetManager.shared.showWhatsNew() {
			SheetManager.shared.sheetSelection = .whatsNew
			SheetManager.shared.showSheet = true
		} else {
			if BLEAutoconnectManager.shared.shouldDisplayConnectSheet() {
				SheetManager.shared.sheetSelection = .connect
				SheetManager.shared.showSheet = true
				SheetManager.shared.upToDate = true
			}
		}
	}
	
	struct CurrentSheet: View {
		var body: some View {
			switch SheetManager.shared.sheetSelection {
			case .onboarding:
				Onboarding()
			case .connect:
				Connect()
			case .notification:
				ArbitraryNotificationSheet()
			case .whatsNew:
				WhatsNew()
			case .chartSettings:
				ChartSettingsSheet()
			case .stepSettings:
				StepSettingsSheet()
			}
		}
	}
}
