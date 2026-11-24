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
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var showHelpAlert = false
    @State private var showAllDevices = false
    @State private var deviceWithPendingConnectionID: UUID?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    func connect(_ device: CBPeripheral) {
        deviceWithPendingConnectionID = device.identifier
        bleManager.connect(peripheral: device)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
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
                                            .background {
                                                DiscoveryPulse(reduceMotion: reduceMotion)
                                            }
                                        Text(infiniTime.name ?? "InfiniTime")
                                            .font(.title.weight(.bold))
                                        if let rssi = bleManager.discoveredRSSI[infiniTime.identifier] {
                                            SignalStrengthView(rssi: rssi)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        connect(infiniTime)
                                    } label: {
                                        Text("Connect")
                                            .padding()
                                            .font(.body.weight(.semibold))
                                            .frame(maxWidth: .infinity)
                                            .foregroundStyle(deviceWithPendingConnectionID == nil ? .white : .clear)
                                            .glassBackground(.blue)
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
                                .onAppear {
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
                                                        Text(device.name ?? "InfiniTime")
                                                            .font(.system(size: 19).weight(.semibold))
                                                            .foregroundStyle(.primary)
                                                        if let rssi = bleManager.discoveredRSSI[device.identifier] {
                                                            SignalStrengthView(rssi: rssi)
                                                                .font(.subheadline)
                                                        }
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
                            if MockWatch.isAvailable {
                                Button("Pair Simulated Watch") {
                                    MockWatch.shared.connect()
                                    dismiss()
                                }
                                .padding(.top, 8)
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

struct SignalStrengthView: View {
    let rssi: Int
    
    var body: some View {
        let strength = RSSI.from(rssi: rssi)
        
        HStack(spacing: 0) {
            Text("Signal: ")
                .foregroundStyle(.gray)
            Text(strength.connectionStrength)
                .foregroundStyle(strength.color)
        }
    }
}

#Preview {
    ConnectView()
}

private struct DiscoveryPulse: View {
    let reduceMotion: Bool
    
    @State private var isAnimating = false
    
    private let duration = 4.0
    
    var body: some View {
        if !reduceMotion {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .scaleEffect(isAnimating ? 2.4 : 0.4)
                .blur(radius: isAnimating ? 16 : 0)
                .animation(.timingCurve(0.1, 0.8, 0.2, 1, duration: duration).repeatForever(autoreverses: false), value: isAnimating)
                .opacity(isAnimating ? 0 : 1)
                .animation(.timingCurve(0.2, 0.6, 0.3, 1, duration: duration).repeatForever(autoreverses: false), value: isAnimating)
                .allowsHitTesting(false)
                .onAppear {
                    isAnimating = true
                }
        }
    }
}
