//
//  DetailHeaderView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct Header {
    let title: String
    let titleUnits: String?
    let icon: String
    let accent: Color
}

struct DetailHeaderSubItemView: View {
    let title: String
    let value: String
    let unit: String?
    
    init(title: String, value: String, unit: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(NSLocalizedString(title, comment: "").uppercased())
                .font(.caption)
                .foregroundStyle(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22).weight(.semibold))
                if let unit {
                    Text(unit)
                        .font(.system(size: 18).weight(.medium))
                        .foregroundColor(.primary.opacity(0.75))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct DetailHeaderView<V: View>: View {
    enum DetailHeaderAnimation {
        case heart
        case sleep
        case steps
    }
    
    let header: Header
    let width: CGFloat
    let animation: DetailHeaderAnimation?
    let headerItems: V
    
    @State private var isHeartAnimating = false
    
    init(_ header: Header,
         width: CGFloat,
         animation: DetailHeaderAnimation? = nil,
         @ViewBuilder headerItems: () -> V) {
        self.header = header
        self.width = width
        self.animation = animation
        self.headerItems = headerItems()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 18) {
                VStack {
                    Image(systemName: header.icon)
                        .foregroundStyle(header.accent)
                        .font(.system(size: width / 3.85))
                        .shadow(color: header.accent.opacity(0.7), radius: isHeartAnimating ? 20 : 0, x: 0, y: 0)
                        .scaleEffect(isHeartAnimating ? 0.85 : 1.0)
                        .animation(
                            .snappy(duration: 1)
                            .repeatForever(autoreverses: true),
                            value: isHeartAnimating
                        )
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(header.title)
                            .font(.system(size: 50).bold())
                        if let units = header.titleUnits {
                            Text(units.uppercased())
                                .foregroundStyle(Color.gray)
                                .font(.system(size: 20).weight(.bold))
                        }
                    }
                }
                headerItems
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            if let animation {
                // TODO: implement other cases
                switch animation {
                case .heart:
                    isHeartAnimating = true
                case .sleep:
                    break
                case .steps:
                    break
                }
            }
        }
    }
}

#Preview {
    DetailHeaderView(Header(title: "89", titleUnits: "BPM", icon: "heart.fill", accent: .red), width: UIScreen.main.bounds.width, animation: .heart) {
        HStack {
            DetailHeaderSubItemView(title: "Distance", value: "1.5", unit: "mi")
            DetailHeaderSubItemView(title: "Kcal", value: "424")
        }
    }
}
