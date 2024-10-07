//
//  DetailHeaderView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct DetailHeaderView: View {
    let geo: CGSize
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: geo.width / 3)
        }
        .overlay {
            
        }
    }
}

#Preview {
    DetailHeaderView(geo: CGSizeMake(3000, 900), icon: , title: "")
}
