//
//  View+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 11/23/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func glassBackground<S: Shape>(_ color: Color? = nil, in shape: S = Capsule()) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(color).interactive(), in: shape)
        } else if let color {
            background(color).clipShape(shape)
        } else {
            background(Material.regular).clipShape(shape)
        }
    }

    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if prominent {
                buttonStyle(.borderedProminent)
            } else {
                buttonStyle(.bordered)
            }
        }
    }
}
