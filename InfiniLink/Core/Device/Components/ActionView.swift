//
//  ActionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import SwiftUI

struct Action {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    let actionLabel: String
    let accent: Color
}

struct ActionView: View {
    let action: Action
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 150, height: 150)
                .foregroundStyle(action.accent)
                .blur(radius: 50)
            VStack(spacing: 20) {
                Image(systemName: action.icon)
                    .font(.system(size: 55).weight(.bold))
                    .foregroundStyle(.primary.opacity(0.6))
                VStack(spacing: 12) {
                    Text(NSLocalizedString(action.title, comment: ""))
                        .font(.largeTitle.weight(.bold))
                    Text(NSLocalizedString(action.subtitle, comment: ""))
                        .foregroundStyle(.gray)
                }
                Button {
                    action.action()
                } label: {
                    Text(NSLocalizedString(action.actionLabel, comment: ""))
                        .padding(12)
                        .padding(.horizontal, 4)
                        .background(action.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .frame(maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}
