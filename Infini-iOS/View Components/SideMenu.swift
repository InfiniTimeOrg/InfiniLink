//
//  SideMenu.swift
//  Infini-iOS
//
//  Created by xan-m on 8/12/21.
//

import SwiftUI

struct SideMenu: View {
	
	@Binding var isOpen: Bool
	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	
	func changePage(newPage: Page){
		withAnimation{
			pageSwitcher.currentPage = newPage
			self.isOpen = false
		}
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Button(action: {changePage(newPage: .status)}) {
					Image(systemName: "heart")
						.foregroundColor(.gray)
						.imageScale(.large)
					Text("Current Stats")
						.foregroundColor(.gray)
						.padding(5)
				}
			}
				.padding(.top, 100)
			HStack {
				Button(action: {changePage(newPage: .dfu)}) {
					Image(systemName: "arrow.up.doc")
						.foregroundColor(.gray)
						.imageScale(.large)
					Text("Update Firmware")
						.foregroundColor(.gray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			HStack {
				Button(action: {changePage(newPage: .settings)}) {
					Image(systemName: "gear")
						.foregroundColor(.gray)
						.imageScale(.large)
					Text("Settings")
						.foregroundColor(.gray)
						.padding(5)
				}
			}
				.padding(.top, 20)
			
			Spacer()
			HStack {
				if !self.bleManager.isConnectedToPinetime {
					Button(action: {
						pageSwitcher.connectViewLoad = true
						pageSwitcher.showMenu = false
					}) {
						Image(systemName: "radiowaves.right")
							.foregroundColor(.gray)
							.imageScale(.large)
						Text("Connect to PineTime")
							.foregroundColor(.gray)
							.padding(5)
					}
				}
			}
				.padding(.top, 100)
			
			VStack (alignment: .center, spacing:10) {
				Text("STATUS")
					.font(.headline)

				
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
			.background(Color.darkGray)
	}
}
