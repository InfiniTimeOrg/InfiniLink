//
//  WelcomeView.swift
//  InfiniLink
//
//  Created by Micah Stanley on 5/2/22.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        return VStack {
            if !bleManager.isConnectedToPinetime || deviceInfo.firmware == "" {
                VStack(spacing: 5) {
                    Text("InfiniLink")
                        //.font(.subheadline(size: 42))
                        .font(.system(size: 42))
                        .bold()
                        .padding(5)
                    Text("Welcome. If you have an InfiniTime device, \n you can pair it here.")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        //.font(.subheadline(size: 42))
                        .font(.system(size: 16))
                        //.bold()
                    //
                    Image("WelcomePineTime")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        //.frame(width: 110, height: 110)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if bleManager.isConnectedToPinetime {
                        
                        ProgressView("Connecting...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(45)
                        //Button("") {
                            
                        //}.buttonStyle(NeumorphicButtonStyle(bgColor: .darkGray))
                         //   .frame(maxWidth: .infinity, alignment: .center)
                         //   .padding(45)
                    } else {
                        Button("Start Pairing") {
                            if !bleManager.isConnectedToPinetime {
                                SheetManager.shared.sheetSelection = .connect
                                SheetManager.shared.showSheet = true
                            }
                        }.buttonStyle(NeumorphicButtonStyle(bgColor: .darkGray))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(45)
                    }
                }
                .padding(5)
            }
                //.padding(5)
            else {
                HomeScreen()
            }
           // List() {
                //Section() {
                //}
               // .listRowBackground(Color.clear)
            //}
            //.listStyle(.insetGrouped)
            //.navigationBarTitle(Text("Customize Favorites").font(.subheadline), displayMode: .inline)
        }
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var bgColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .shadow(color: .white, radius: configuration.isPressed ? 7: 10, x: configuration.isPressed ? -5: -15, y: configuration.isPressed ? -5: -15)
                        .shadow(color: .black, radius: configuration.isPressed ? 7: 10, x: configuration.isPressed ? 5: 15, y: configuration.isPressed ? 5: 15)
                        .blendMode(.overlay)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(bgColor)
                }
        )
            .scaleEffect(configuration.isPressed ? 0.95: 1)
            .foregroundColor(.primary)
            .animation(.spring())
        
    }
}
