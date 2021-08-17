//
//  PhoneNotificationsView.swift
//  Infini-iOS
//
//  Created by xan-m on 8/16/21.
//  
//
    

import Foundation
import SwiftUI

struct PhoneNotifications: View {
	
	// not calling this view for now because I have like 3 settings to manipulate.
	// TODO: decide if this view is even necessary, and delete if not
	
	var body: some View {
		VStack {
			Text("Phone Notifications")
				.font(.largeTitle)
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(.bottom, 30)
		}
		Spacer()
	}
}
