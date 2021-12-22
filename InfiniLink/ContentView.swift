//
//  ContentView.swift
//  InfiniLink
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
	@AppStorage("onboarding") var onboarding: Bool!// = false
	@AppStorage("lastVersion") var lastVersion: String = ""
	let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
	

	
	
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
					UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
					withAnimation {
						pageSwitcher.showMenu = false
					}
				} else if $0.translation.width > 100 {
					UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
					withAnimation {
						pageSwitcher.showMenu = true
					}
				}
			}

		NavigationView {
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					MainView()
						.sheet(isPresented: $sheetManager.showSheet, content: {
							SheetManager.CurrentSheet()
								.onDisappear {
									if !sheetManager.upToDate {
										if onboarding == nil {
											onboarding = false
										}
										sheetManager.setNextSheet(autoconnect: autoconnect, autoconnectUUID: autoconnectUUID)
									}
								}
						})
						.onChange(of: bleManager.batteryLevel) { bat in
							batteryNotifications.notify(bat: Int(bat), bleManager: bleManager)
						}
//						.offset(x: pageSwitcher.showMenu ? geometry.size.width * 0.6 : 0)
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
									.ignoresSafeArea()
							}
						})
						// alert to handle errors thrown by SetTime
						.alert(isPresented: $bleManager.setTimeError, content: {
							Alert(title: Text(NSLocalizedString("failed_set_time", comment: "")), message: Text(NSLocalizedString("failed_set_time_description", comment: "")), dismissButton: .default(Text(NSLocalizedString("dismiss", comment: ""))))
						})

						.onAppear(){
							// if autoconnect is set, start scan ASAP, but give bleManager half a second to start up
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
								if autoconnect && bleManager.isSwitchedOn {
									self.bleManager.startScanning()
								}
								sheetManager.setNextSheet(autoconnect: autoconnect, autoconnectUUID: autoconnectUUID)
							})
						}
					if pageSwitcher.showMenu {
						if #available(iOS 15.0, *) {
							SideMenu()
								.dynamicTypeSize(.large ... .accessibility5)
								.frame(width: geometry.size.width * 0.6)
								.transition(.move(edge: .leading))
								.ignoresSafeArea()
								.zIndex(10)
						} else {
							SideMenu()
								.frame(width: geometry.size.width * 0.6)
								.minimumScaleFactor(1.5)
								.transition(.move(edge: .leading))
								.ignoresSafeArea()
								.zIndex(10)
						}
					}
				}
				.navigationBarItems(leading: (
					Button(action: {
						UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
						withAnimation {
							pageSwitcher.showMenu.toggle()
						}
					}) {
						Image(systemName: "line.horizontal.3")
							.padding(.vertical, 10)
							.padding(.horizontal, 7)
							.imageScale(.large)
							.foregroundColor(Color.gray)
					}))
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
