//
//  GithubAuthView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/29/24.
//

import SwiftUI

struct GithubAuthView: View {
    var body: some View {
        ActionView(action: Action(title: "Sign In to GitHub", subtitle: "You'll need to be signed into GitHub to install updates from Actions.", icon: "key.fill", action: {
            // TODO: open oauth sheet
        }, actionLabel: "Connect to GitHub", accent: .gray))
    }
}

#Preview {
    GithubAuthView()
}
