//
//  MainView.swift
//  MainView
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import Foundation
import SwiftUI

struct MainView: View {

	@ObservedObject var pageSwitcher: PageSwitcher = PageSwitcher.shared
	@EnvironmentObject var bleManager: BLEManager
	
	
	var body: some View {
		switch pageSwitcher.currentPage {
		case .dfu:
			DFUView()
		case .status:
			StatusView()
		case .settings:
			Settings_Page()
		case .home:
			HomeScreen()
		}
	}
}
