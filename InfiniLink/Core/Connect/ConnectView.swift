//
//  ConnectView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/3/24.
//

import SwiftUI
import CoreBluetooth

struct ConnectView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var showHelpAlert = false
    @State private var showAllDevices = false
    @State private var deviceWithPendingConnectionID: UUID?
    
    @State private var circleSize: CGFloat = 60
    @State private var circleOpacity: CGFloat = 1
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    func connect(_ device: CBPeripheral) {
        deviceWithPendingConnectionID = device.identifier
        bleManager.connect(peripheral: device) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
    }
    
    func startCircleAnimation(geo: CGSize) {
        animateCircle(geo: geo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resetCircle()
            animateCircle(geo: geo)
        }
    }
    func animateCircle(geo: CGSize) {
        withAnimation(.easeInOut(duration: 1.2)) {
            circleSize = geo.width / 2
            circleOpacity = 0
        }
    }
    func resetCircle() {
        circleSize = 0
        circleOpacity = 1
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    if bleManager.isBluetoothOn {
                        if bleManager.newPeripherals.isEmpty {
                            ProgressView("Looking for your watch...")
                                .frame(maxHeight: .infinity)
                        } else if let infiniTime = bleManager.newPeripherals.first {
                            if !showAllDevices {
                                VStack {
                                    Spacer()
                                    VStack(spacing: 16) {
                                        Text("1 device discovered")
                                            .foregroundStyle(.gray)
                                        Image(.pineTime)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 150)
                                        Text("InfiniTime")
                                            .font(.title.weight(.bold))
                                    }
                                    Spacer()
                                    Button {
                                        connect(infiniTime)
                                    } label: {
                                        Text("Connect")
                                            .padding()
                                            .font(.body.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .foregroundStyle(deviceWithPendingConnectionID == nil ? .white : .clear)
                                            .overlay {
                                                if deviceWithPendingConnectionID != nil {
                                                    ProgressView()
                                                        .tint(.white)
                                                }
                                            }
                                    }
                                    .disabled(deviceWithPendingConnectionID != nil)
                                    
                                    let count = bleManager.newPeripherals.count - 1
                                    if count >= 1 {
                                        Button("\(count) more device\(count == 1 ? "" : "s") found") {
                                            showAllDevices = true
                                        }
                                    }
                                }
                                .background {
                                    // Discovery animation; is there a more efficient way to do this?
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: circleSize, height: circleSize)
                                        .opacity(circleOpacity)
                                        .offset(y: -48)
                                }
                                .onAppear {
                                    startCircleAnimation(geo: geo.size)
                                    bleManager.stopScanning()
                                }
                            } else {
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 10) {
                                        ForEach(bleManager.newPeripherals, id: \.identifier) { device in
                                            Button {
                                                connect(device)
                                            } label: {
                                                VStack {
                                                    if deviceWithPendingConnectionID != nil {
                                                        ProgressView()
                                                    } else {
                                                        Image("PineTime")
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(height: 70)
                                                        Text("InfiniTime")
                                                            .font(.system(size: 19).weight(.semibold))
                                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                    }
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: geo.size.width / 2.1)
                                                .background(Material.regular)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if bleManager.newPeripherals.isEmpty {
                            Button {
                                showHelpAlert = true
                            } label: {
                                Text("Device not appearing?")
                            }
                            .alert(isPresented: $showHelpAlert) {
                                Alert(title: Text("Ensure that your watch is not connected to another device. If the issue persists, press and hold the side button until the watch restarts."))
                            }
                        }
                    } else {
                        Text("Bluetooth needs to be enabled to pair a watch.")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            }
            .onAppear {
                bleManager.scanForNewDevices()
            }
            .onDisappear {
                if bleManager.isConnectedToPinetime { // Don't stop scanning if there's no device connected
                    bleManager.stopScanning()
                }
            }
        }
    }
}

#Preview {
    ConnectView()
}
