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
			Text(NSLocalizedString("whats_new_body_1", comment: ""))
				.padding()
			Text(NSLocalizedString("whats_new_body_2", comment: ""))
				.padding()
			Text(NSLocalizedString("whats_new_body_3", comment: ""))
				.padding()
		}
	}
}

