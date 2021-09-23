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
	
	struct CurrentSheet: View {
		@ObservedObject var bleManager = BLEManager.shared
		var body: some View {
			switch SheetManager.shared.sheetSelection {
			case .onboarding:
				Onboarding()
			case .connect:
				Connect().environmentObject(bleManager)
			case .notification:
				ArbitraryNotificationSheet()
			}
		}
	}
	
	func setView(sheet: SheetSelection, bleManager: BLEManager) -> AnyView {
		switch sheet {
		case .onboarding:
			return AnyView(Onboarding())
		case .connect:
			return AnyView(Connect().environmentObject(bleManager))
		case .notification:
			return AnyView(Color.black)
		}
	}
}
