//
//  HeartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct HeartView: View {
    var body: some View {
        ScrollView {
            DetailHeaderView(Header(title: String(format: "%.0f", BLEManager.shared.heartRate), titleUnits: "BPM", icon: "heart.fill", accent: .red), width: UIScreen.main.bounds.width) {
                HStack {
                    DetailHeaderSubItemView(title: "Avg", value: "157")
                    DetailHeaderSubItemView(title: "Min", value: "64")
                    DetailHeaderSubItemView(title: "Max", value: "186")
                }
            }
        }
        .navigationTitle("Heart Rate")
        .toolbar {
            NavigationLink {
                HeartSettingsView()
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    NavigationView {
        HeartView()
            .navigationBarTitleDisplayMode(.inline)
    }
}
