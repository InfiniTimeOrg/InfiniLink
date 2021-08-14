//
//  PageSwitcher.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/12/21.
//

import Foundation

enum Page {
	case connect
	case dfu
	case status
}

class PageSwitcher: ObservableObject {
	
	@Published var currentPage: Page = .connect

}
