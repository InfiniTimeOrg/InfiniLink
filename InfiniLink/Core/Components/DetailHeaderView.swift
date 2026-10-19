//
//  DetailHeaderView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData

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
        self.accent =  accent
    }
}

struct DetailHeaderSubItemView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ScaledMetric private var iconSize: CGFloat = 21
    @ScaledMetric private var valueSize: CGFloat = 22
    @ScaledMetric private var unitSize: CGFloat = 17
    
    let title: String
    let value: String
    let unit: String?
    let icon: (String, Color)?
    let completion: (() -> Void)?
    
    init(title: String, value: String, unit: String? = nil, icon: (String, Color)? = nil, completion: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.completion = completion
    }
    
    var body: some View {
        HStack(spacing: 9) {
            if let name = icon?.0, let color = icon?.1 {
                Image(systemName: name)
                    .foregroundStyle(color)
                    .font(.system(size: iconSize).weight(.medium))
                    .frame(minWidth: 30)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 3) {
                    Text(title.uppercased())
                        .font(.caption.weight(.medium))
                    if let completion {
                        Button {
                            completion()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("More Info"))
                    }
                }
                .foregroundStyle(.gray)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: valueSize).weight(.semibold))
                    if let unit {
                        Text(unit)
                            .font(.system(size: unitSize).weight(.medium))
                            .foregroundColor(.primary.opacity(0.75))
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(colorScheme == .dark ? AnyShapeStyle(Material.regular) : AnyShapeStyle(Color(.systemBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .accessibilityElement(children: completion == nil ? .combine : .contain)
    }
}

struct DetailHeaderView<V: View>: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    enum DetailHeaderAnimation {
        case heart
        case steps
    }
    
    let header: Header
    let width: CGFloat
    let animate: Bool
    let animateTitle: Bool
    let headerItems: V
    
    @State private var isHeartAnimating = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @ScaledMetric private var titleSize: CGFloat = 50
    @ScaledMetric private var unitsSize: CGFloat = 20
    @ScaledMetric private var subtitleSize: CGFloat = 17.5
    
    func updateAnimState() {
        if let last = heartPoints.last?.timestamp, abs(last.timeIntervalSinceNow) < 60 && animate && !reduceMotion {
            isHeartAnimating = true
        }
    }
    
    init(_ header: Header,
         width: CGFloat,
         animate: Bool = false,
         animateTitle: Bool = true,
         @ViewBuilder headerItems: () -> V) {
        self.header = header
        self.width = width
        self.animate = animate
        self.animateTitle = animateTitle
        self.headerItems = headerItems()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 18) {
                VStack {
                    Image(systemName: header.icon)
                        .foregroundStyle(header.accent)
                        .font(.system(size: min(width / 4.4, 115)))
                        .accessibilityHidden(true)
                        .scaleEffect(isHeartAnimating ? 0.85 : 1.0)
                        .animation(
                            .snappy(duration: 0.9)
                            .repeatForever(autoreverses: true),
                            value: isHeartAnimating
                        )
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(header.title)
                            .font(.system(size: titleSize).bold())
                            .contentTransition(.numericText())
                            .animation(animateTitle ? .default : nil, value: header.title)
                        if let units = header.units {
                            Text(units.uppercased())
                                .foregroundStyle(.primary.opacity(0.8))
                                .font(.system(size: unitsSize).weight(.bold))
                        }
                    }
                    if let subtitle = header.subtitle {
                        Text(subtitle)
                            .foregroundStyle(.gray)
                            .font(.system(size: subtitleSize).weight(.medium))
                    }
                }
                .accessibilityElement(children: .combine)
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
