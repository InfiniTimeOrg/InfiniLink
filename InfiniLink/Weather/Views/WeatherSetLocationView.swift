//
//  WeatherSetLocationView.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/22/24.
//

import SwiftUI

struct WeatherSetLocationView: View {
    @AppStorage("setLocation") var setLocation: String = "Cupertino"
    
    @State private var location = ""
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .darkGray)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                Text(NSLocalizedString("set_location", comment: ""))
                    .foregroundColor(.primary)
                    .font(.title.weight(.bold))
                Spacer()
                Button {
                    setLocation = location
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(NSLocalizedString("save", comment: ""))
                        .padding(14)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color.white)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .center)
            Divider()
            VStack {
                TextField("Cupertino", text: $location)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            location = setLocation
        }
    }
}

#Preview {
    WeatherSetLocationView()
}
