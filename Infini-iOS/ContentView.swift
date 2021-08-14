//
//  ContentView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/5/21.
//

import SwiftUI
import CoreData

struct ContentView: View {

	@State var showMenu = false
	
	var body: some View {
		
		let drag = DragGesture()
			.onEnded {
				if $0.translation.width < -100 {
					withAnimation {
						self.showMenu = false
					}
				} 
			}
		
		return NavigationView {
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					MainView(showMenu: self.$showMenu)
						.frame(width: geometry.size.width, height: geometry.size.height)
						.offset(x: self.showMenu ? geometry.size.width/2 : 0)
						.disabled(self.showMenu ? true : false)
					if self.showMenu {
						MenuView(isOpen: self.$showMenu)
							.frame(width: geometry.size.width/2)
							.transition(.move(edge: .leading))
					}
				}
					.gesture(drag)
			}
				//.navigationBarTitle("Infini-iOS", displayMode: .inline)
				.navigationBarItems(leading: (
					Button(action: {
						withAnimation {
							self.showMenu.toggle()
						}
					}) {
						Image(systemName: "line.horizontal.3")
							.imageScale(.large)
							.foregroundColor(Color.white)
					}
				))
		}
	}
}

struct MainView: View {
	
	@Binding var showMenu: Bool
	@State var currentPage: Page = .connect
	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	
	var body: some View {
		switch pageSwitcher.currentPage {
		case .connect:
			Connect()
		case .dfu:
			DFU_Page(dfuUpdater: DFU_Updater(ble: bleManager))
		case .status:
			DeviceView()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environmentObject(PageSwitcher())
	}
}
