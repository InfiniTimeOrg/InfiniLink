//
//  Onboarding.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/29/21.
//  
//
    

import SwiftUI

struct Onboarding: View {
	
	var body: some View {
		ScrollView{
			VStack {
				Text("🎉 Welcome to Infini-iOS! 🎉")
					.font(.title2)
					.padding()
				Text("I'm thrilled you're willing and able to test out this beta version of my iOS companion app for InfiniTime! Before you begin, make sure to allow this app to use Bluetooth. Please report any issues that you find, crashes you experience, or suggested changes to me! Your feedback allows you and me to work together to have a great companion app. Reports are welcome through TestFlight, or through GitHub, Matrix, or Mastodon (links are available in the settings tab).")
					.padding()
				
				OnboardingBody()
				OnboardingDismissButton()
			}
		}
	}
}
