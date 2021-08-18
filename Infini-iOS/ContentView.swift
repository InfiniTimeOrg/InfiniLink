//
//  ContentView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/5/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
	
	//@State var showMenu = false
	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	
	init() {
		UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
		UINavigationBar.appearance().shadowImage = UIImage()
		UINavigationBar.appearance().isTranslucent = true
		UINavigationBar.appearance().tintColor = .clear
		UINavigationBar.appearance().backgroundColor = .clear
	}
	
	
	var body: some View {
		let drag = DragGesture()
			.onEnded {
				if $0.translation.width < -100 {
					withAnimation {
						self.pageSwitcher.showMenu = false
					}
				} else if $0.translation.width > 100 {
					withAnimation {
						self.pageSwitcher.showMenu = true
					}
				//} else if $0.translation.height < -300 {
				//	pageSwitcher.connectViewLoad = true
				}
			}
		
		return NavigationView {
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					MainView()
						.sheet(isPresented: $pageSwitcher.connectViewLoad, content: {
							Connect().environmentObject(self.bleManager)
						})
						.frame(width: geometry.size.width, height: geometry.size.height)
						.offset(x: self.pageSwitcher.showMenu ? geometry.size.width/2 : 0)
						.disabled(self.pageSwitcher.showMenu ? true : false)
						.onAppear(){
							// if autoconnect is set, start scan ASAP, but give bleManager half a second to start up
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
								if autoconnect && bleManager.isSwitchedOn {
									self.bleManager.startScanning()
								}
							})
							if (autoconnect && autoconnectUUID == "") || (!autoconnect && !bleManager.isConnectedToPinetime) {
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
									withAnimation {
										pageSwitcher.connectViewLoad = true
									}
								})
							}
						}
					if self.pageSwitcher.showMenu {
						SideMenu(isOpen: self.$pageSwitcher.showMenu)
							.frame(width: geometry.size.width/2)
							.transition(.move(edge: .leading))
							.ignoresSafeArea()
					}
				}
				.navigationBarItems(leading: (
					Button(action: {
						withAnimation {
							self.pageSwitcher.showMenu.toggle()
						}
					}) {
						Image(systemName: "line.horizontal.3")
							.imageScale(.large)
							.foregroundColor(Color.gray)
					}
				))
				.background(Color.black)
				.navigationBarTitleDisplayMode(.inline)
			}
			.gesture(drag)
		}
	}
}
	
struct MainView: View {

	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	
	
	var body: some View {
		switch pageSwitcher.currentPage {
		case .dfu:
			DFU_Page(dfuUpdater: DFU_Updater(ble: bleManager))
		case .status:
			DeviceView()
		case .settings:
			Settings_Page()
		}
	}
}

	
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environmentObject(PageSwitcher())
			.environmentObject(BLEManager())
	}
}

