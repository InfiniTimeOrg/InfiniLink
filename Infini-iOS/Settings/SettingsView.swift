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
	
	@State var showGreeting: Bool = false
	
	var body: some View {
		VStack{
			Toggle("testing", isOn: $showGreeting)
			if showGreeting {
				Text("on")
			}
		}
	}
}
