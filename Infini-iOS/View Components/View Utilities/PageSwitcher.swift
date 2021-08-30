//
//  PageSwitcher.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/12/21.
//

import Foundation

enum Page {
	case dfu
	case status
	case settings
}

class PageSwitcher: ObservableObject {
	
	@Published var currentPage: Page = .status
	@Published var connectViewLoad: Bool = false
	@Published var showMenu: Bool = false
	
}
