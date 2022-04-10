//
//  WhatsNewSheet.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/28/21.
//  
//
    

import SwiftUI

struct WhatsNew: View {
	
	let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
	
	var body: some View {
		SheetCloseButton()
		ScrollView{
			VStack {
				Text(String("\(NSLocalizedString("whats_new_in", comment: "")) v\(appVersion!)"))
					.font(.largeTitle)
					.padding(.horizontal)
				Text("\(NSLocalizedString("welcome_to_version", comment: "")) \(appVersion!).")
					.padding()
				Text("\(NSLocalizedString("welcome_text", comment: ""))")
					.padding()
				
				WhatsNewBody()
				OnboardingDismissButton()
			}
		}
	}
}
