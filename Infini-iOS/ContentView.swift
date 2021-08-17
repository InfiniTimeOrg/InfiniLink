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
	@EnvironmentObject var pageSwitcher: PageSwitcher
	@EnvironmentObject var bleManager: BLEManager
	
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
						self.showMenu = false
					}
				} else if $0.translation.width > 100 {
					withAnimation {
						self.showMenu = true
					}
				}
			}
		if bleManager.batteryLevel == "20" {
			let batNotification = UserDefaults.standard.object(forKey: "batteryNotification") as? Bool ?? false
			if batNotification {
				bleManager.sendNotification(notification: "Battery at 20%")
				print("20")
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
						SideMenu(isOpen: self.$showMenu)
							.frame(width: geometry.size.width/2)
							.transition(.move(edge: .leading))
							.ignoresSafeArea()
					}
				}
			}
			.navigationBarItems(leading: (
				Button(action: {
					withAnimation {
						self.showMenu.toggle()
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

