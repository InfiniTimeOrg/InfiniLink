//
//  ActionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import SwiftUI

struct ActionButton {
    let action: () -> Void
    let label: String
}

struct Action {
    let title: String
    let subtitle: String
    let icon: String
    let button: ActionButton?
    let accent: Color
    
    init(title: String, subtitle: String, icon: String, button: ActionButton? = nil, accent: Color) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.button = button
        self.accent = accent
    }
}

struct ActionView: View {
    let action: Action
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 140, height: 140)
                .foregroundStyle(action.accent)
                .blur(radius: 50)
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .padding(10)
                    .font(.body.weight(.semibold))
                    .background(action.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(NSLocalizedString(action.title, comment: ""))
                    .font(.system(size: 28).weight(.bold))
                Text(NSLocalizedString(action.subtitle, comment: ""))
                    .foregroundStyle(.primary.opacity(0.8))
                if let button = action.button {
                    Button {
                        button.action()
                    } label: {
                        Text(NSLocalizedString(button.label, comment: ""))
                            .padding(12)
                            .padding(.horizontal, 6)
                            .font(.body.weight(.semibold))
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .padding()
                }
            }
            .frame(maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(24)
        }
    }
}

#Preview {
    ActionView(action: Action(title: "Reminders", subtitle: "We need access to your reminders to notify you about them on your watch.", icon: "list.bullet", button: .init(action: {}, label: "Open Settings..."), accent: .blue))
}
