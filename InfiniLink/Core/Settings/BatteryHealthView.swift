//
//  BatteryHealthView.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/11/26.
//

import SwiftUI

struct BatteryHealthView: View {
    var body: some View {
        List {
            BatteryStatsSectionView()
        }
        .navigationTitle("Battery Health")
    }
}

#Preview {
    NavigationStack {
        BatteryHealthView()
    }
}
