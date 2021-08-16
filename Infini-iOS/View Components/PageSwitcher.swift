//
//  PageSwitcher.swift
//  Infini-iOS
//
//  Created by xan-m on 8/12/21.
//

import Foundation

enum Page {
	case connect
	case dfu
	case status
	case settings
}

class PageSwitcher: ObservableObject {
	
	@Published var currentPage: Page = .connect

}
