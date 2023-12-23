//
//  ConnectionHelpView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/22/23.
//

import SwiftUI

struct ConnectionHelpView: View {
    @Binding var isDisplayed: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("connection_help", comment: "Connection Help"))
                    .font(.title.bold())
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Button(action: {isDisplayed = false}) {
                    Image(systemName: "xmark")
                        .imageScale(.medium)
                        .padding(12)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.darkGray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(.vertical, 10)
                .padding()
            }
            Divider()
                .padding(.bottom)
            Text(NSLocalizedString("other_notes_4", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

#Preview {
    ConnectionHelpView(isDisplayed: .constant(true))
}
