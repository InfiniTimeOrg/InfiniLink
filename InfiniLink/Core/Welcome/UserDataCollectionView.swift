//
//  UserDataCollectionView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct UserDataCollectionView: View {
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Let's get you set up.")
                            .font(.largeTitle.weight(.bold))
                        Text("To accurately measure calories and steps, we'll need to know your height and weight.")
                            .foregroundStyle(.gray)
                    }
                    .frame(width: geo.size.width / 1.4, alignment: .leading)
                    Button("Skip") {
                        PersonalizationController.shared.showSetupSheet = false
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Spacer()
                // TODO: implement more views
            }
            .padding()
        }
    }
}

#Preview {
    UserDataCollectionView()
}
