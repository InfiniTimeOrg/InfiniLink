//
//  AppRowView.swift
//  InfiniLink
//
//  Created by Liam Willey on 2/10/24.
//

import SwiftUI

struct AppRowView: View {
    let app: MiniApp
    
    @AppStorage("installedApps") var installedApps: [String] = []
    
    init(app: MiniApp) {
        self.app = app
    }
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(app.title)
                    .font(.system(size: 20).weight(.semibold))
                Text(app.description)
            }
            Divider()
                .padding(.horizontal, -16)
            if installedApps.contains(app.id) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle")
                    Text("Enabled")
                    Spacer()
                    Button {
                        if let index = installedApps.firstIndex(of: app.id) {
                            installedApps.remove(at: index)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Button {
                    installedApps.append(app.id)
                } label: {
                    Text("Enable")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(15)
    }
}

#Preview {
    AppRowView(app: MiniApp(id: "todo", title: "To-Do", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."))
}
