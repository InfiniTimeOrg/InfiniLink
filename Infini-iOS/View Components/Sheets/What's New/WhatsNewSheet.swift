//
//  WhatsNewSheet.swift
//  Infini-iOS
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
				Text(String("What's New in \(appVersion!)"))
					.font(.title2)
					.padding(.horizontal)
				Text("Welcome to the new version of Infini-iOS! I hope you enjoy the features I've added to the app for this version. Please feel free to get in touch with me about any issues you experience or changes you'd like to see!")
					.padding()
				
				WhatsNew090()
				OnboardingDismissButton()
			}
		}
	}
}
