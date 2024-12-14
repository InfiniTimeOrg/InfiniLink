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
            VStack(spacing: 16) {
                Image(systemName: action.icon)
                    .font(.system(size: 45).weight(.bold))
                    .foregroundStyle(.primary.opacity(0.6))
                VStack(spacing: 10) {
                    Text(NSLocalizedString(action.title, comment: ""))
                        .font(.system(size: 25).weight(.bold))
                    Text(NSLocalizedString(action.subtitle, comment: ""))
                        .foregroundStyle(.primary.opacity(0.8))
                }
                Button {
                    action.action()
                } label: {
                    Text(NSLocalizedString(action.actionLabel, comment: ""))
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .background(Color.blue)
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

#Preview {
    ActionView(action: Action(title: "Reminders", subtitle: "We need access to your reminders to notify you about them on your watch.", icon: "list.bullet", action: {}, actionLabel: "Open Settings...", accent: .blue))
}
