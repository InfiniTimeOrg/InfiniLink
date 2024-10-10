//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct SleepView: View {
    var body: some View {
        GeometryReader { geo in
            List {
                Section {
                    DetailHeaderView(Header(title: "8", units: "Hours", icon: "bed.double.fill", accent: .purple), width: geo.size.width) {
                        HStack {
                            DetailHeaderSubItemView(title: "Deep", value: "2.5hrs")
                            DetailHeaderSubItemView(title: "Core", value: "5hrs")
                            DetailHeaderSubItemView(title: "REM", value: "2hrs")
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Sleep")
    }
}

#Preview {
    SleepView()
}
