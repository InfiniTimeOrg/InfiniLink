//
//  BLEView.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/11/21.
//

import Foundation
import SwiftUI

struct Connect: View {
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.presentationMode) var presentation
    @AppStorage("autoconnect") var autoconnect: Bool = false
    @AppStorage("autoconnectUUID") var autoconnectUUID: String = ""
    @State var showHelpView = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    Text(NSLocalizedString("available_devices", comment: ""))
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SheetCloseButton()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                HStack {
                    Text("\(bleManager.newPeripherals.count) \(NSLocalizedString("devices", comment: "Devices"))")
                        .padding()
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                    Spacer()
                    if bleManager.isSwitchedOn && !bleManager.newPeripherals.isEmpty {
                        HStack(spacing: 7) {
                            ProgressView()
                            Text(NSLocalizedString("scanning", comment: "Scanning"))
                        }
                        .padding()
                        .font(.body.weight(.semibold))
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 10)
            .padding()
            Divider()
            if bleManager.isSwitchedOn {
                if bleManager.newPeripherals.isEmpty {
                    HStack(spacing: 7) {
                        ProgressView()
                        Text(NSLocalizedString("scanning", comment: "Scanning"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.gray)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(bleManager.newPeripherals, id: \.identifier.uuidString) { i in
                                let deviceName = DeviceNameManager.init().getName(deviceUUID: i.identifier.uuidString)
                                Button {
                                    bleManager.connect(peripheral: i)
                                    presentation.wrappedValue.dismiss()
                                } label: {
                                    Text(deviceName == "" ? i.name ?? NSLocalizedString("unnamed", comment: "") : deviceName)
                                        .frame(maxWidth: .infinity)
                                        .font(.body.weight(.semibold))
                                        .padding()
                                        .foregroundColor(.primary)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                HStack(spacing: 7) {
                    ProgressView()
                    Text(NSLocalizedString("waiting_for_bluetooth", comment: "Waiting for Bluetooth"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.gray)
            }
            Divider()
                .padding(.bottom)
            Button(action: {
                showHelpView.toggle()
            }) {
                Text(NSLocalizedString("need_help_connecting", comment: "Need help connecting?"))
                    .padding(11)
                    .padding(.horizontal, 6)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            .sheet(isPresented: $showHelpView) {
                ConnectionHelpView(isDisplayed: $showHelpView)
            }
            .padding(.bottom)
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

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        Connect()
    }
}
