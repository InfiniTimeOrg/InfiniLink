//
//  DetailHeaderView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct Header {
    let title: String
    let subtitle: String?
    let units: String?
    let icon: String
    let accent: Color
    
    init(title: String, subtitle: String? = nil, units: String? = nil, icon: String, accent: Color) {
        self.title = title
        self.subtitle = subtitle
        self.units = units
        self.icon = icon
        self.accent = accent
    }
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
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22).weight(.semibold))
                if let unit {
                    Text(unit)
                        .font(.system(size: 17.5))
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
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    enum DetailHeaderAnimation {
        case heart
        case sleep
        case steps
    }
    
    let header: Header
    let width: CGFloat
    let animate: Bool
    let headerItems: V
    
    @State private var isHeartAnimating = false
    
    func updateAnimState() {
        if let last = heartPoints.last?.timestamp, abs(last.timeIntervalSinceNow) < 60 && animate {
            isHeartAnimating = true
        }
    }
    
    init(_ header: Header,
         width: CGFloat,
         animate: Bool = false,
         @ViewBuilder headerItems: () -> V) {
        self.header = header
        self.width = width
        self.animate = animate
        self.headerItems = headerItems()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 18) {
                VStack {
                    Image(systemName: header.icon)
                        .foregroundStyle(header.accent)
                        .font(.system(size: min(width / 4.4, 115)))
                        .shadow(color: header.accent.opacity(0.7), radius: isHeartAnimating ? 20 : 0, x: 0, y: 0)
                        .scaleEffect(isHeartAnimating ? 0.85 : 1.0)
                        .animation(
                            .snappy(duration: 0.9)
                            .repeatForever(autoreverses: true),
                            value: isHeartAnimating
                        )
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(header.title)
                            .font(.system(size: 50).bold())
                        if let units = header.units {
                            Text(units.uppercased())
                                .foregroundStyle(.primary.opacity(0.8))
                                .font(.system(size: 20).weight(.bold))
                        }
                    }
                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .foregroundStyle(.gray)
                            .font(.system(size: 17.5).weight(.medium))
                    }
                }
                headerItems
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            updateAnimState()
        }
        .onChange(of: Array(heartPoints)) { _ in
            updateAnimState()
        }
    }
}

#Preview {
    DetailHeaderView(Header(title: "89", subtitle: "4 minutes ago", units: "BPM", icon: "heart.fill", accent: .red), width: UIScreen.main.bounds.width, animate: true) {
        HStack {
            DetailHeaderSubItemView(title: "Distance", value: "1.5", unit: "mi")
            DetailHeaderSubItemView(title: "Kcal", value: "424")
        }
    }
}
