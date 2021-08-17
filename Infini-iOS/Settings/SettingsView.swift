//
//  SettingsView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/15/21.
//  
//
    

import Foundation
import SwiftUI

struct Settings_Page: View {
	
	@EnvironmentObject var bleManager: BLEManager
	
	@AppStorage("watchNotifications") var watchNotifications: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("batteryNotification") var batteryNotification: Bool = false

	
	var body: some View {
		VStack (alignment: .leading){
			Text("Settings")
				.font(.largeTitle)
				.padding()
			Form {
				Section(header: Text("Connection")) {
					Toggle("Autoconnect to Nearest PineTime", isOn: $autoconnect)
					if autoconnect {
					Text("Warning! Autoconnect is insecure! Only use in safe environments.").foregroundColor(Color.red)
					}
				}
				Section(header: Text("Notifications")) {
					Toggle("Enable Watch Notifications", isOn: $watchNotifications)
					Toggle("Notify about Low Battery", isOn: $batteryNotification)
				}
			}
		}

	}
}
