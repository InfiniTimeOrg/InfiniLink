//
//  WatchNotificationsView.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/16/21.
//  
//
    

import Foundation
import SwiftUI

struct WatchNotifications: View {
	
	// not calling this view for now because I have like 3 settings to manipulate.
	// TODO: decide if this view is even necessary, and delete if not
	
	@AppStorage("watchNotifications") var watchNotifications: Bool = true
	@AppStorage("autoconnect") var autoconnect: Bool = false
	@AppStorage("batteryNotification") var batteryNotification: Bool = false

	
	var body: some View {
		VStack (alignment: .leading){
			Text("Watch Settings")
				.font(.largeTitle)
				.padding(.bottom, 10)
		}
		Form {
			Toggle("Watch Notifications", isOn: $watchNotifications)
			Toggle("Autoconnect", isOn: $autoconnect)
			Toggle("Notify about Low Battery", isOn: $batteryNotification)
		}
	}
}
