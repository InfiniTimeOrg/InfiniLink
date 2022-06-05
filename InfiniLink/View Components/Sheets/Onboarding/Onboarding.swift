//
//  Onboarding.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/29/21.
//  
//
    

import SwiftUI

struct Onboarding: View {
	
	var body: some View {
		SheetCloseButton()
		ScrollView{
			VStack {
				Text(NSLocalizedString("welcome_to_InfiniLink", comment: ""))
					.font(.title2)
					.padding(.horizontal)
				Text(NSLocalizedString("onboarding_text", comment: ""))
					.padding()
				
				OnboardingBody()
				OnboardingDismissButton()
			}
		}
	}
}
