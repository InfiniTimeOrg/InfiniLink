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
                    ZStack {
                        DeviceView()
                            .disabled(true)
                            .blur(radius: 70)
                        VStack(spacing: 16) {
                            Text(NSLocalizedString("connecting", comment: "Connecting..."))
                                .font(.title.weight(.bold))
                            Button {
                                bleManager.disconnect()
                            } label: {
                                Text(NSLocalizedString("stop_connecting", comment: "Stop Connecting"))
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } else {
                    VStack() {
                        VStack(spacing: 5) {
                            Spacer()
                            Text("InfiniLink")
                                .font(.system(size: 36).weight(.bold))
                                .bold()
                                .padding(.bottom)
                            Button(NSLocalizedString("start_pairing", comment: "")) {
                                SheetManager.shared.sheetSelection = .connect
                                SheetManager.shared.showSheet = true
                            }
                            .buttonStyle(NeumorphicButtonStyle(bgColor: colorScheme == .dark ? Color.darkGray : Color.lightGray))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom)
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .fullBackground(imageName: "LaunchScreen")
                }
                
            } else {
                DeviceView()
            }
        }
        .onAppear {
            if bleManager.isSwitchedOn {
                bleManager.startScanning()
            }
        }
        .onDisappear {
            if bleManager.isScanning {
                bleManager.stopScanning()
            }
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
            .foregroundColor(.primary)
    }
}

public extension View {
    func fullBackground(imageName: String) -> some View {
       return background(
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
       )
    }
}
