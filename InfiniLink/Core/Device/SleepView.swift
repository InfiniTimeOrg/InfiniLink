//
//  SleepView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI

struct SleepView: View {
    var body: some View {
        ScrollView {
            DetailHeaderView(Header(title: "8", titleUnits: "Hours", icon: "bed.double.fill", accent: .purple), width: UIScreen.main.bounds.width) {
                HStack {
                    DetailHeaderSubItemView(title: "Deep", value: "2.5hrs")
                    DetailHeaderSubItemView(title: "Core", value: "5hrs")
                    DetailHeaderSubItemView(title: "REM", value: "2hrs")
                }
            }
        }
        .navigationTitle("Sleep")
    }
}

#Preview {
    SleepView()
}
