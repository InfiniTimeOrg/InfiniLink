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
            HStack(spacing: 3) {
                Text(value)
                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.gray)
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
    let header: Header
    let width: CGFloat
    let headerItems: V
    
    init(_ header: Header,
         width: CGFloat,
         @ViewBuilder headerItems: () -> V) {
        self.header = header
        self.width = width
        self.headerItems = headerItems()
    }
    
    private var iconSize: CGFloat {
        width / 3
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: header.icon)
                    .foregroundStyle(header.accent)
                    .font(.system(size: iconSize))
                    .frame(width: iconSize / 1.5, alignment: .trailing)
                    .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(header.title)
                            .font(.system(size: 50).bold())
                        
                        if let titleUnits = header.titleUnits {
                            Text(titleUnits.uppercased())
                                .font(.system(size: 19).weight(.medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    headerItems
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
}

#Preview {
    DetailHeaderView(Header(title: "100", titleUnits: "%", icon: "battery.100percent", accent: .green), width: UIScreen.main.bounds.width) {
        HStack {
            DetailHeaderSubItemView(title: "Distance", value: "1.5mi")
            DetailHeaderSubItemView(title: "Kcal", value: "424")
        }
    }
}
