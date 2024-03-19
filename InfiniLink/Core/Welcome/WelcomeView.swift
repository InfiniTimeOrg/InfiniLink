//
//  WelcomeView.swift
//  InfiniLink
//
//  Created by John Stanley on 5/2/22.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var deviceInfo = BLEDeviceInfo.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if !bleManager.isConnectedToPinetime || deviceInfo.firmware == "" || bleManagerVal.watchFace == -1 {
                if bleManager.isConnectedToPinetime {
                    ZStack {
                        DeviceView()
                            .disabled(true)
                            .blur(radius: 70)
                        Group {
                            if deviceInfo.firmware != "" && (bleManagerVal.watchFace == -1 && bleManager.blefsTransfer == nil) {
                                VStack(spacing: 18) {
                                    Group {
                                        Text(NSLocalizedString("recovery_mode", comment: "It looks like your device is in recovery mode."))
                                            .font(.title.weight(.bold))
                                        Text(NSLocalizedString("exit_recovery_mode", comment: "To exit Recovery Mode, you need to install a software update."))
                                    }
                                    .multilineTextAlignment(.center)
                                    VStack(spacing: 12) {
                                        NavigationLink {
                                            DFUView()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(NSLocalizedString("software_update", comment: "Software Update"))
                                                Image(systemName: "chevron.right")
                                            }
                                            .padding()
                                            .background(Material.thin)
                                            .foregroundColor(.primary)
                                            .clipShape(Capsule())
                                        }
                                        Button {
                                            bleManager.disconnect()
                                        } label: {
                                            Text(NSLocalizedString("disconnect", comment: "Disconnect"))
                                                .padding()
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            } else {
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
                        }
                        .padding()
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
        ZStack {
            DeviceView()
                .disabled(true)
                .blur(radius: 70)
            VStack(spacing: 18) {
                Group {
                    Text(NSLocalizedString("recovery_mode", comment: "It looks like your device is in recovery mode."))
                        .font(.title.weight(.bold))
                    Text("To exit Recovery Mode, you need to install a software update.")
                }
                .multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    NavigationLink {
                        DFUView()
                    } label: {
                        HStack(spacing: 6) {
                            Text(NSLocalizedString("software_update", comment: "Software Update"))
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Material.thin)
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    }
                    Button {
                        BLEManager.shared.disconnect()
                    } label: {
                        Text(NSLocalizedString("disconnect", comment: "Disconnect"))
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
    }
}
