//
//  WhatsNewBody090.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/28/21.
//  
//
    

import SwiftUI

struct WhatsNewBody: View {
	
	var body: some View {
		ScrollView{
			Text(NSLocalizedString("step_counter", comment: ""))
				.padding()
			Text(NSLocalizedString("apple_music", comment: ""))
				.padding()
			Text(NSLocalizedString("new_logo", comment: ""))
				.padding()
		}
	}
}

