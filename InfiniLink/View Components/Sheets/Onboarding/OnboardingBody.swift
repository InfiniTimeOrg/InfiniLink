//
//  OnboardingBody.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/15/21.
//  
//
    

import SwiftUI

struct OnboardingBody: View {
	
	var body: some View {
		ScrollView{
			VStack {
				
				Text(NSLocalizedString("other_notes", comment: ""))
					.font(.title2)
					.padding()
				Text(NSLocalizedString("other_notes_1", comment: ""))
					.padding()
				Text(NSLocalizedString("other_notes_2", comment: ""))
					.padding()
				Text(NSLocalizedString("other_notes_3", comment: ""))
					.padding()
				Text(NSLocalizedString("other_notes_4", comment: ""))
					.padding()
			}
		}
	}
}
