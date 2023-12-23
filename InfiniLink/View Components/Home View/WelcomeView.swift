//
//  WelcomeView.swift
//  InfiniLink
//
//  Created by John Stanley on 5/2/22.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if !bleManager.isConnectedToPinetime || deviceInfo.firmware == "" {
                if bleManager.isConnectedToPinetime {
                    DeviceView()
                } else {
                    VStack(spacing: 5) {
                        Text("InfiniLink")
                            .font(.system(size: 34).weight(.bold))
                            .bold()
                            .padding(5)
                        Text(NSLocalizedString("welcome_text", comment: ""))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.gray)
                            .font(.body)
                        Spacer()
                        Image("WelcomePineTime")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                        Button(NSLocalizedString("start_pairing", comment: "")) {
                            SheetManager.shared.sheetSelection = .connect
                            SheetManager.shared.showSheet = true
                        }
                        .buttonStyle(NeumorphicButtonStyle(bgColor: colorScheme == .dark ? Color.darkGray : Color.lightGray))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                    .padding()
                }
            } else {
                DeviceView()
            }
        }
        // DEBUG
        .onAppear {
            deviceInfo.firmware = "1.13.0"
            bleManager.isConnectedToPinetime = true
        }
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var bgColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.body.weight(.semibold))
            .foregroundColor(Color.white)
            .background(Color.blue)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95: 1)
            .foregroundColor(.primary)
            .animation(.spring())
    }
}
