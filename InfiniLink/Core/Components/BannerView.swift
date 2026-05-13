//
//  BannerView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/13/26.
//

import SwiftUI

struct BannerView<V: View>: View {
    let title: LocalizedStringKey
    let caption: LocalizedStringKey?
    let subtitle: LocalizedStringKey
    let image: V
    
    init(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey, _ caption: LocalizedStringKey? = nil, @ViewBuilder image: () -> V) {
        self.title = title
        self.caption = caption
        self.subtitle = subtitle
        self.image = image()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            image
            VStack(alignment: .leading, spacing: 3) {
                if let caption {
                    Text(caption)
                        .font(.system(size: 13).weight(.medium))
                        .foregroundStyle(.gray)
                }
                Text(title)
                    .foregroundStyle(Color.primary)
                    .fontWeight(.bold)
                Text(subtitle)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BannerView(
        "InfiniLink",
        "1.16.2",
        "Update Available"
    ) {
        Image((UIApplication.shared.alternateIconName ?? "AppIcon") + "-Rendered")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .padding()
}
