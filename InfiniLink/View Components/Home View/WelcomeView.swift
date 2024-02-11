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
                            .blur(radius: 64)
                        Rectangle()
                            .ignoresSafeArea()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.background)
                            .opacity(0.25)
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
                    ZStack {
                        GeometryReader { geometry in
                            Image("WatchHomePagePineTime")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width * 2.15, height: geometry.size.width * 2.15, alignment: .center)
                                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 1.94)
                                .shadow(color: colorScheme == .dark ? Color.darkGray : Color.lightGray, radius: 128, x: 0, y: 0)
                                .brightness(colorScheme == .dark ? -0.01 : 0.06)
                            Text("Welcome to\nInfiniLink")
                                .font(.largeTitle.weight(.bold))
                                .foregroundColor(colorScheme == .dark ? Color.lightGray : Color.darkGray)
                                .position(x: geometry.size.width / 2.0, y: geometry.size.height / 7.5)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        VStack() {
                            VStack(spacing: 5) {
                                Spacer()
                                VStack(spacing: 6) {
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
                                .clipped()
                                .shadow(color: colorScheme == .dark ? Color.darkGray : Color.white, radius: 30, x: 0, y: 0)
                            }
                            .padding()
                        }
                    }
                }
                
            } else {
                DeviceView()
            }
        }
        .background {
            ZStack {
                VStack {
                    Circle()
                        .fill(Color("Blue"))
                        .scaleEffect(0.7)
                        .offset(x: 20)
                        .blur(radius: 60)
                    Circle()
                        .fill(Color("Blue"))
                        .scaleEffect(0.7, anchor: .leading)
                        .offset(y: -20)
                        .blur(radius: 56)
    
                }
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .opacity(0.9)
            }
            .ignoresSafeArea()
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
        .navigationBarHidden(true)
        
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

#Preview {
    NavigationView {
        ContentView()
            .onAppear {
                BLEManager.shared.isConnectedToPinetime = false
                //BLEManagerVal.shared.firmwareVersion = "1.13.0"
            }
    }
}
