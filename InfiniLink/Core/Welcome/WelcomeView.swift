//
//  WelcomeView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.openURL) var openURL
    
    @State private var showPairingSheet = false
    
    var greeting: String {
        let date = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        
        switch currentHour {
        case 0..<12:
            return NSLocalizedString("Good morning", comment: "")
        case 12..<18:
            return NSLocalizedString("Good afternoon", comment: "")
        case 18..<24:
            return NSLocalizedString("Good evening", comment: "")
        default:
            return NSLocalizedString("Hello", comment: "")
        }
    }
    var infoURL: URL? {
        guard let url = URL(string: "https://wiki.pine64.org/wiki/PineTime") else { return nil }
        
        // Check if the user's device has browser capabilties
        if UIApplication.shared.canOpenURL(url) {
            return url
        } else {
            return nil
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(greeting)!")
                        .font(.largeTitle.weight(.bold))
                    Text("If you have an InfiniTime device, you can pair it here.")
                        .foregroundStyle(.gray)
                    if let url = infoURL {
                        Button {
                            openURL(url)
                        } label: {
                            Text("Learn more")
                                .font(.body.weight(.bold))
                        }
                    }
                }
                .frame(width: geo.size.width / 1.4, alignment: .leading)
                Spacer()
                Button {
                    showPairingSheet = true
                } label: {
                    Text("Start Pairing")
                        .padding()
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .sheet(isPresented: $showPairingSheet) {
                    ConnectView()
                }
                .padding(.bottom)
            }
            .padding(20)
            .background {
                Image(.welcomeScreen)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WelcomeView()
}
