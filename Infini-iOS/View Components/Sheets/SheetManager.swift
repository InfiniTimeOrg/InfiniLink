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
	case downloadUpdate
}

class SheetManager: ObservableObject {
	static let shared = SheetManager()
	
	@Published var showSheet: Bool = false
	@Published var sheetSelection: SheetSelection = .connect
	
	struct CurrentSheet: View {
		var body: some View {
			switch SheetManager.shared.sheetSelection {
			case .onboarding:
				Onboarding()
			case .connect:
				Connect()
			case .notification:
				ArbitraryNotificationSheet()
			case .downloadUpdate:
				DownloadView()
			}
		}
	}
}
