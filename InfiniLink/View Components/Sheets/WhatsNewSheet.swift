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
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("welcome_to_version", comment: "") + " \(appVersion!)")
                    .font(.title.bold())
                Spacer()
                SheetCloseButton()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(NSLocalizedString("whats_new_body_1", comment: ""))
                    Text(NSLocalizedString("whats_new_body_2", comment: ""))
                }
                .padding()
            }
        }
	}
}
