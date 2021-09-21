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
}

class SheetManager: ObservableObject {
	static let shared = SheetManager()
		
	@Published var showSheet: Bool = false
	var sheetSelection: SheetSelection!
	
	func setView(isOnboarding: Bool, bleManager: BLEManager) -> AnyView {
		if isOnboarding{
			return AnyView(Onboarding())
		} else {
			return AnyView(Connect().environmentObject(bleManager))
		}
	}
}
