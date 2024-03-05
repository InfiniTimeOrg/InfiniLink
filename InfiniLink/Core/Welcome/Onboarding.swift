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
                        Text(NSLocalizedString("other_notes", comment: ""))
                            .font(.title2.weight(.semibold))
                    ForEach(0...3, id: \.self) { index in
                        Text(NSLocalizedString("other_notes_\(index + 1)", comment: ""))
                    }
                }
                .padding()
            }
        }
	}
}
