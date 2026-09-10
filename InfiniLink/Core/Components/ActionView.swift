//
//  ActionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/15/24.
//

import SwiftUI

struct ActionButton: Identifiable {
    let id = UUID()
    let label: String
    let role: ButtonRole?
    let action: () -> Void

    init(_ label: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.label = label
        self.role = role
        self.action = action
    }
}

struct Action {
    var title: String
    var subtitle: String
    var icon: String
    var accent: Color
    var buttons: [ActionButton] = []
}

struct ActionView: View {
    let action: Action

    init(_ action: Action) {
        self.action = action
    }

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
                    .background(action.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(NSLocalizedString(action.title, comment: ""))
                    .font(.title.weight(.bold))
                Text(NSLocalizedString(action.subtitle, comment: ""))
                    .foregroundStyle(.primary.opacity(0.8))
                if !action.buttons.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(action.buttons) { button in
                            Button(role: button.role, action: button.action) {
                                Text(NSLocalizedString(button.label, comment: ""))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 18)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(foreground(for: button.role))
                                    .background(background(for: button.role))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                }
            }
            .frame(maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding(24)
        }
    }

    private func background(for role: ButtonRole?) -> Color {
        if role == .destructive { return .red }
        if role == .cancel { return Color.primary.opacity(0.08) }
        return .blue
    }

    private func foreground(for role: ButtonRole?) -> Color {
        return role == .cancel ? .primary : .white
    }
}

#Preview {
    ActionView(Action(
        title: "Reminders",
        subtitle: "We need access to your reminders to notify you about them on your watch.",
        icon: "list.bullet",
        accent: .blue,
        buttons: [
            ActionButton("Open Settings...") {},
            ActionButton("Not Now", role: .cancel) {}
        ]
    ))
}
