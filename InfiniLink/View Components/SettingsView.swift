//
//  SettingsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/15/21.
//  
//
    

import Foundation
import SwiftUI

struct Settings_Page: View {
	
	@ObservedObject var bleManager = BLEManager.shared
    //@ObservedObject var bleManagerVal = BLEManagerVal.shared
	@ObservedObject var deviceInfo = BLEDeviceInfo.shared
    
    @ObservedObject private var deviceDataForSettings: DeviceData = deviceData
    //@ObservedObject private var selfDeviceDataForSettings: BLEManagerVal = selfDeviceData
	//@ObservedObject var pageSwitcher = PageSwitcher.shared
	@Environment(\.colorScheme) var colorScheme
	
    
    //@AppStorage("chosenTheme") var chosenTheme = "System Default"
	@AppStorage("watchNotifications") var watchNotifications: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("batteryNotification") var batteryNotification: Bool = false
	@AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
	@AppStorage("heartChartFill") var heartChartFill: Bool = true
	@AppStorage("batChartFill") var batChartFill: Bool = true
	@AppStorage("debugMode") var debugMode: Bool = false
	@AppStorage("showNewDownloadsOnly") var showNewDownloadsOnly: Bool = false
	@FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ChartDataPoint.timestamp, ascending: true)])
	private var chartPoints: FetchedResults<ChartDataPoint>
	
	@State private var changedName: String = ""
	private var nameManager = DeviceNameManager()
	@State private var deviceName = ""
	
	var body: some View {
		VStack {
			List {
                                
                //if UIApplication.shared.supportsAlternateIcons {
                //    NavigationLink {
                //        AppIconPicker()
                //            .environmentObject(selfDeviceDataForSettings)
                //    } label: {
                //        HStack {
                //            Label("App Icon", systemImage: "app")
                //                .accentColor(.primary)
                //            Spacer()
                //            selfDeviceDataForSettings.appIcon.name
                //                .foregroundColor(.secondary)
                //        }
                //    }
                //}
                
                Section(header: Text("App Settings")
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                            
                    NavigationLink(destination: SettingsChosenThemeView(chosenTheme: $deviceDataForSettings.chosenTheme)) {
                        HStack {
                            Text("App Theme")
                                //.accentColor(.primary)
                            Spacer()
                            Text(deviceData.chosenTheme)
                                .foregroundColor(.secondary)
                        }
                    }
                                
                    NavigationLink(destination: CustomizeFavoritesView()) {
                        Text("Customize Favorites")
                    }
                    if bleManager.isConnectedToPinetime && deviceInfo.firmware != "" {
                        Button {
                            SheetManager.shared.sheetSelection = .connect
                            SheetManager.shared.showSheet = true
                        } label: {
                            Text("Pair New Device")
                        }
                    }
                    Toggle("Enable Debug Mode", isOn: $debugMode)
                    if debugMode {
                        NavigationLink(destination: DebugView()) {
                            Text("Debug Logs")
                        }
                    }
                }
				
				Section(header: Text("Firmware Update Downloads")) {
					Toggle("Show Newer Versions Only", isOn: $showNewDownloadsOnly)
				}
				

				Section(header: Text("Graph Styles")) {
					Toggle("Filled HRM Graph", isOn: $heartChartFill)
					Toggle("Filled Battery Graph", isOn: $batChartFill)
				}
                
                if autoconnectUUID != "" {
                    Section(header: Text("Connect Options")) {
                        Button {
                            autoconnectUUID = ""
                            bleManager.autoconnectToDevice = false
                            DebugLogManager.shared.debug(error: "Autoconnect Device Cleared", log: .app, date: Date())
                        } label: {
                            Text("Clear Autoconnect Device")
                        }.disabled(!autoconnect || autoconnectUUID.isEmpty)
                    }
                }
                
				Section(header: Text("Graph Data")) {
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.heart.rawValue)
					}) {
						(Text("Clear All HRM Chart Data"))
					}
					Button (action: {
						ChartManager.shared.deleteAll(dataSet: chartPoints, chart: ChartsAsInts.battery.rawValue)
					}) {
						(Text("Clear All Battery Chart Data"))
					}
				}
				
				Section(header: Text("Onboarding Information")) {
					
					Button {
						SheetManager.shared.sheetSelection = .onboarding
						SheetManager.shared.showSheet = true
					} label: {
						Text("Open Onboarding Page")
					}
					Button {
						SheetManager.shared.sheetSelection = .whatsNew
						SheetManager.shared.showSheet = true
					} label: {
						Text("Open 'What's New' Page for This Version")
					}
				}
                
                Section(header: Text("Links")
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                    Link("InfiniLink GitHub", destination: URL(string: "https://github.com/xan-m/InfiniLink")!)
                    Link("Matrix", destination: URL(string: "https://matrix.to/#/@xanm:matrix.org")!)
                    Link("Mastodon", destination: URL(string: "https://fosstodon.org/@xanm")!)
                    Link("InfiniTime Firmware Releases", destination: URL(string: "https://github.com/JF002/InfiniTime/releases")!)
                }
                
                Section(header: Text("Donations")
                            .font(.system(size: 14))
                            .bold()
                            .padding(1)) {
                    Link("PayPal Donation", destination: URL(string: "https://paypal.me/alexemry")!)
                }
			}
			.listStyle(.insetGrouped)
		}
	}
}
