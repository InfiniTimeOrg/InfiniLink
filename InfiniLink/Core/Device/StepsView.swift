//
//  StepsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

struct StepsView: View {
    @ObservedObject var bleManager = BLEManager.shared
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                DetailHeaderView(Header(title: String(bleManager.stepCount), titleUnits: "Steps", icon: "shoeprints.fill", accent: .blue), width: geo.size.width) {
                    HStack {
                        DetailHeaderSubItemView(title: "Dis", value: "1mi")
                        DetailHeaderSubItemView(title: "Kcal", value: "186")
                    }
                }
            }
        }
        .navigationTitle("Steps")
        .toolbar {
            
        }
    }
}

#Preview {
    StepsView()
}
