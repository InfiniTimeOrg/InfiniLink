//
//  AppsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 2/10/24.
//

import SwiftUI

struct MiniApp: Equatable, Codable {
    // Use id to decide what each app does
    // Each id needs to be unique
    let id: String
    let title: String
    let description: String
}

struct AppsView: View {
    @AppStorage("installedApps") var installedApps: [String] = []
    @State var apps: [MiniApp] = [
        MiniApp(id: "To-Do", title: "To-Do", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text(NSLocalizedString("apps", comment: "Apps"))
                .foregroundColor(.primary)
                .font(.title.weight(.bold))
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            ScrollView {
                VStack {
                    ForEach(apps, id: \.id) { app in
                        AppRowView(app: app)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    AppsView()
}
