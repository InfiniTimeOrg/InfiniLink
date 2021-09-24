//
//  SheetManager.swift
//  Infini-iOS
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
}

class SheetManager: ObservableObject {
	static let shared = SheetManager()
	
	@Published var showSheet: Bool = false
	@Published var sheetSelection: SheetSelection = .connect
	
//	init() {
//		let onboarding = UserDefaults.standard.object(forKey: "onboarding") as? Bool ?? true
//		if onboarding {
//			sheetSelection = .onboarding
//			print(sheetSelection)
//		}
//	}
	
	struct CurrentSheet: View {
		var body: some View {
			switch SheetManager.shared.sheetSelection {
			case .onboarding:
				Onboarding()
			case .connect:
				Connect()
			case .notification:
				ArbitraryNotificationSheet()
			}
		}
	}
}
