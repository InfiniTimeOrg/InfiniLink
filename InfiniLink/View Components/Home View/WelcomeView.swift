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
                            Text("Welcome to \nInfiniLink")
                                .font(.system(size: 33).weight(.bold))
                                .padding(9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                            VStack(spacing: 12) {
                                Button {
                                    SheetManager.shared.sheetSelection = .connect
                                    SheetManager.shared.showSheet = true
                                } label: {
                                    Text(NSLocalizedString("start_pairing", comment: ""))
                                        .modifier(NeumorphicButtonModifer(bgColor: colorScheme == .dark ? Color.darkGray : Color.lightGray))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 5)
                                .padding(.horizontal)
                                .onAppear {
                                    if bleManager.isSwitchedOn {
                                        bleManager.startScanning()
                                    }
                                }
                                VStack(spacing: 7) {
                                    Text("Don't have a Watch?")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.horizontal)
                                        .foregroundColor(.gray)
                                    Link(destination: URL(string: "https://wiki.pine64.org/wiki/PineTime")!) {
                                        Text("Learn more about the PineTime")
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 5)
                                            .padding(.horizontal)
                                            .font(.body.weight(.semibold))
                                    }
                                }
                            }
                            .clipped()
                            .shadow(color: colorScheme == .dark ? Color.darkGray : Color.white, radius: 30, x: 0, y: 0)
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

struct NeumorphicButtonModifer: ViewModifier {
    var bgColor: Color

    func body(content: Content) -> some View {
        content
            .padding()
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
                    .offset(y: -23)
       )
    }
}

#Preview {
    NavigationView {
        ContentView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = false
                //BLEManagerVal.shared.firmwareVersion = "1.14.0"
            }
    }
}
