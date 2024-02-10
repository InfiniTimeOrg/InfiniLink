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
                                .font(.system(size: 38).weight(.bold))
                                .padding(32)
                                //.padding(.top)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                            if bleManager.isSwitchedOn {
                                Button {
                                    SheetManager.shared.sheetSelection = .connect
                                    SheetManager.shared.showSheet = true
                                } label: {
                                    Text(NSLocalizedString("start_pairing", comment: ""))
                                        .modifier(NeumorphicButtonModifer(bgColor: colorScheme == .dark ? Color.darkGray : Color.lightGray))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom)
                                .padding(.horizontal)
                                .onAppear {
                                    if bleManager.isSwitchedOn {
                                        bleManager.startScanning()
                                    }
                                }
                            } else {
                                Text("Bluetooth is Disabled")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom)
                                    .padding(.bottom)
                                    .padding(.horizontal)
                            }
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
       )
    }
}

#Preview {
    NavigationView {
        ContentView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = false
                //BLEManagerVal.shared.firmwareVersion = "1.13.0"
            }
    }
}
