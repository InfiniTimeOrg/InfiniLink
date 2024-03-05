//
//  HeartChartView.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/4/24.
//

import SwiftUI

struct HeartChartView: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: HeartView()) {
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text(NSLocalizedString("heart_rate", comment: ""))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(Int(bleManagerVal.heartBPM)))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text(NSLocalizedString("bpm", comment: ""))
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}

#Preview {
    HeartChartView()
}
