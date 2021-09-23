//
//  ContentView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

struct ContentView: View {
	
	@ObservedObject var bleManager = BLEManager.shared
	
	@ObservedObject var pageSwitcher = PageSwitcher.shared
	@ObservedObject var batteryNotifications = BatteryNotifications()
	@ObservedObject var sheetManager = SheetManager.shared

	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	@AppStorage("batteryNotification") var batteryNotification: Bool = false
	@AppStorage("onboarding") var onboarding: Bool = true
	
	
	init() {
		UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
		UINavigationBar.appearance().shadowImage = UIImage()
		UINavigationBar.appearance().isTranslucent = true
		UINavigationBar.appearance().tintColor = .clear
		UINavigationBar.appearance().backgroundColor = .clear
	}
	
	var body: some View {
		let drag = DragGesture()
			// this drag gesture allows swiping right to open the side menu and left to close the side menu
			.onEnded {
				if $0.translation.width < -100 {
					withAnimation {
						pageSwitcher.showMenu = false
					}
				} else if $0.translation.width > 100 {
					withAnimation {
						pageSwitcher.showMenu = true
					}
				}
			}

		NavigationView {
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					MainView()
						//.environmentObject(sheetManager)
						.sheet(isPresented: $sheetManager.showSheet, content: {
							SheetManager.CurrentSheet().environmentObject(bleManager)
								.onDisappear {
									if onboarding {
										onboarding = false
										SheetManager.shared.showSheet = true
									}
								}
						})
						.onChange(of: bleManager.batteryLevel) { bat in
							batteryNotifications.notify(bat: Int(bat), bleManager: bleManager)
						}
						.offset(x: pageSwitcher.showMenu ? geometry.size.width/2 : 0)
						.disabled(pageSwitcher.showMenu ? true : false)
						.overlay(Group {
							// this overlay lets you tap on the main screen to close the side menu. swiftUI requires a view that is not Color.clear and has any opacity level > 0 for tap interactions
							if pageSwitcher.showMenu {
								Color.black
									.opacity(pageSwitcher.showMenu ? 0.3 : 0)
									.onTapGesture {
										withAnimation {
											pageSwitcher.showMenu = false
										}
									}
							}
						})
						// alert to handle errors thrown by SetTime
						.alert(isPresented: $bleManager.setTimeError, content: {
							Alert(title: Text("Failed to Set Time"), message: Text("There was an issue setting the time on your watch. Please disconnect from the watch, and then reconnect."), dismissButton: .default(Text("Dismiss")))
						})

						.onAppear(){
							// if autoconnect is set, start scan ASAP, but give bleManager half a second to start up
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
								if autoconnect && bleManager.isSwitchedOn {
									self.bleManager.startScanning()
								}
								
								if (autoconnect && autoconnectUUID == "") || (!autoconnect && !bleManager.isConnectedToPinetime) || onboarding {
									SheetManager.shared.sheetSelection = .connect
									SheetManager.shared.showSheet = true
								}
							})
						}
					if pageSwitcher.showMenu {
						SideMenu(isOpen: $pageSwitcher.showMenu)
							.frame(width: geometry.size.width/2)
							.transition(.move(edge: .leading))
							.ignoresSafeArea()
					}
				}
				.navigationBarItems(leading: (
					Button(action: {
						withAnimation {
							pageSwitcher.showMenu.toggle()
						}
					}) {
						Image(systemName: "line.horizontal.3")
							.padding(.vertical, 10)
							.padding(.horizontal, 7)
							.imageScale(.large)
							.foregroundColor(Color.gray)
					}
				))
				.navigationBarTitleDisplayMode(.inline)
			}
			
		}.gesture(drag)
	}
}


	
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
			.environmentObject(BLEManager())
			.environmentObject(DFU_Updater())
	}
}
