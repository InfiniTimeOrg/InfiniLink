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
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("welcome_to_InfiniLink", comment: ""))
                    .font(.title.bold())
                Spacer()
                SheetCloseButton()
            }
            .padding()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(NSLocalizedString("onboarding_text", comment: ""))
                    VStack(alignment: .leading, spacing: 20) {
                        Text(NSLocalizedString("other_notes", comment: ""))
                            .font(.title2.weight(.semibold))
                        Text(NSLocalizedString("other_notes_1", comment: ""))
                        Text(NSLocalizedString("other_notes_2", comment: ""))
                        Text(NSLocalizedString("other_notes_3", comment: ""))
                        Text(NSLocalizedString("other_notes_4", comment: ""))
                    }
                }
                .padding()
            }
        }
	}
}
