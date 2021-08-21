//
//  PageSwitcher.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/12/21.
//

import Foundation

enum Page {
	//case connect
	case dfu
	case status
	case settings
}

class PageSwitcher: ObservableObject {
	
	@Published var currentPage: Page = .status
	@Published var currentPageTitle: String = "Connect to Your Device"
	@Published var connectViewLoad: Bool = false
	@Published var showMenu: Bool = false
	
	/*init() {
		if UserDefaults.standard.object(forKey: "autoconnect") as! Bool {
			currentPage = .status
		} else {
			currentPage = .connect
		}
	}*/
}

class connectViewLoader: ObservableObject {
	@Published var load: Bool = false
}
