//
//  SideMenu.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/12/21.
//

import SwiftUI

struct SideMenu: View {
	
	@Binding var isOpen: Bool
	@ObservedObject var pageSwitcher: PageSwitcher = PageSwitcher.shared
	@ObservedObject var bleManager = BLEManager.shared
	@Environment(\.colorScheme) var colorScheme
	
	func changePage(newPage: Page) {
		withAnimation() {
			pageSwitcher.currentPage = newPage
			self.isOpen = false
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Button(action: {changePage(newPage: .home)}) {
					Image(systemName: "house.fill")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.imageScale(.large)
					Text("Home")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 100)
			HStack {
				Button(action: {changePage(newPage: .status)}) {
					Image(systemName: "heart")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.imageScale(.large)
					Text("Charts")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			HStack {
				Button(action: {changePage(newPage: .dfu)}) {
					Image(systemName: "arrow.up.doc")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.imageScale(.large)
					Text("Update Firmware")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			HStack {
				Button(action: {changePage(newPage: .settings)}) {
					Image(systemName: "gear")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.imageScale(.large)
					Text("Settings")
						.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			
			Spacer()
			HStack {
				if !self.bleManager.isConnectedToPinetime {
					Button(action: {
						SheetManager.shared.sheetSelection = .connect
						SheetManager.shared.showSheet = true
						pageSwitcher.showMenu = false
					}) {
						Image(systemName: "radiowaves.right")
							.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
							.imageScale(.large)
						Text("Connect to PineTime")
							.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)
							.padding(5)
					}
				}
			}
				.padding(.top, 100)
			
			VStack (alignment: .center, spacing:10) {
				Text("STATUS")
					.font(.headline)
					.foregroundColor(colorScheme == .dark ? Color.gray : Color.darkGray)

				
				if bleManager.isSwitchedOn {
					Text("Bluetooth On")
						.foregroundColor(.green)
				}
				else {
					Text("Bluetooth Off")
						.foregroundColor(.red)
				}
				
				if bleManager.isConnectedToPinetime {
					Text("Connected")
						.foregroundColor(.green)
				}
				else {
					Text("Disconnected")
						.foregroundColor(.red)
				}
			}
			.padding()
			.frame(maxWidth: .infinity, alignment: .center)
			
		}
			.padding(20)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(colorScheme == .dark ? Color.darkGray : Color.lightGray)
	}
}
