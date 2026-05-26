//
//  MyDevicesView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/17/24.
//

import SwiftUI
import CoreData

struct MyDevicesView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Device.name, ascending: true)], animation: .default) var devices: FetchedResults<Device>
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var bleManager = BLEManager.shared
    
    @State private var showConnectSheet = false
    @State private var showDetailsView = false
    @State private var showUnpairConfirmation = false
    
    @State private var selectedWatch: Device?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(devices, id: \.self) { watch in
                        HStack {
                            Button {
                                bleManager.switchDevice(device: watch)
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .font(.body.weight(.semibold))
                                        .opacity(deviceManager.pairedDeviceID  == watch.uuid ? 1 : 0)
                                    WatchFaceView(watchface: UInt8(watch.watchface), device: watch)
                                        .frame(width: 90, height: 90)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(watch.name ?? "InfiniTime")
                                            .foregroundStyle(Color.primary)
                                            .font(.title2.weight(.semibold))
                                        Text({
                                            if let peripheral = bleManager.infiniTime, peripheral.identifier.uuidString == watch.uuid {
                                                return bleManager.connectionState
                                            } else {
                                                return "InfiniTime " + (watch.firmware ?? "")
                                            }
                                        }())
                                        .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                }
                            }
                            .disabled(deviceManager.pairedDeviceID ?? "" == watch.uuid ?? "")
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.accentColor)
                                .onTapGesture {
                                    selectedWatch = watch
                                    showDetailsView = true
                                }
                        }
                        .imageScale(.large)
                    }
                }
                Section {
                    Button {
                        showConnectSheet = true
                        bleManager.isPairingNewDevice = true
                    } label: {
                        Text("Pair New Device")
                    }
                }
            }
            .navigationDestination(isPresented: $showDetailsView) {
                if let selectedWatch {
                    List {
                        Section {
                            AboutRowView("Name", value: selectedWatch.name ?? "InfiniTime")
                            AboutRowView("Software Version", value: selectedWatch.firmware ?? "Unknown")
                            AboutRowView("Manufacturer", value: selectedWatch.manufacturer ?? "Unknown")
                            AboutRowView("Model Name", value: selectedWatch.modelNumber ?? "Unknown")
                        }
                        Section {
                            AboutRowView("File System", value: selectedWatch.blefsVersion ?? "Unknown")
                            AboutRowView("Hardware Revision", value: selectedWatch.hardwareRevision ?? "Unknown")
                        }
                        Section {
                            Button("Unpair", role: .destructive) {
                                showUnpairConfirmation = true
                            }
                            .foregroundStyle(.red)
                            .alert("Are you sure you want to unpair from \(selectedWatch.name ?? "InfiniTime")?", isPresented: $showUnpairConfirmation) {
                                Button(role: .destructive) {
                                    bleManager.unpair(device: selectedWatch)
                                    dismiss()
                                } label: {
                                    Text("Unpair")
                                }
                            }
                        }
                    }
                    .navigationTitle(selectedWatch.name ?? "InfiniTime")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationTitle("My Watches")
            .toolbar {
                Button("Done", role: .cancel) {
                    dismiss()
                }
            }
            .sheet(isPresented: $showConnectSheet, onDismiss: { bleManager.isPairingNewDevice = false }) {
                ConnectView()
            }
        }
    }
}

#Preview {
    MyDevicesView()
}
