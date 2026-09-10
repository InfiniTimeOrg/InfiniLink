//
//  FindLostDeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/31/25.
//

import SwiftUI
import MapKit
import Combine

struct FindLostDeviceView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var chartManager = ChartManager.shared
    @ObservedObject private var deviceManager = DeviceManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    
    private let bleWriteManager = BLEWriteManager()
    private let rssiTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private func focusMap(on point: DisconnectMapPoint) {
        let coordinate = CLLocationCoordinate2D(
            latitude: point.latitude,
            longitude: point.longitude
        )
        
        region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 300,
            longitudinalMeters: 300
        )
        mapId = UUID()
    }
    
    @State private var region = MKCoordinateRegion()
    @State private var mapId = UUID()
    @State private var address = ""
    @State private var pingTimer: Timer? = nil
    @State private var isPinging = false
    
    private func openInMaps(to coordinate: CLLocationCoordinate2D) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = deviceManager.name

        destination.openInMaps(launchOptions: nil)
    }
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                List {
                    VStack(spacing: 8) {
                        Image(systemName: bleManager.isConnectedToPinetime ? "checkmark.circle" : "xmark.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(bleManager.isConnectedToPinetime ? .green : .red)
                        Text("\(deviceManager.name) is \(bleManager.isConnectedToPinetime ? "connected" : "disconnected")")
                            .font(.title2.weight(.bold))
                        if bleManager.isConnectedToPinetime {
                            if let rssiInt = bleManager.rssi {
                                let rssi = RSSI.from(rssi: rssiInt)
                                Text("Your watch is estimated to be around \(String(format: "%.1f\(PersonalizationController.shared.units == .metric ? "m" : "ft")", rssi.estimateDistance(from: rssiInt))) away.")
                                    .foregroundStyle(.gray)
                                HStack(spacing: 0) {
                                    Text("Connection strength: ")
                                    Text(rssi.connectionStrength)
                                        .foregroundStyle(rssi.color)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: min(geo.size.width / 2, 200))
                    .multilineTextAlignment(.center)
                    if let point = chartManager.disconnectMapPoint() {
                        let date = {
                            let timestamp = point.timestamp ?? Date()
                            let dateFormatter = DateFormatter()
                            dateFormatter.timeStyle = .short
                            dateFormatter.dateStyle = .none
                            
                            if bleManager.isConnectedToPinetime {
                                return dateFormatter.string(from: Date())
                            }
                            if abs(timestamp.timeIntervalSinceNow) >= 1440 {
                                dateFormatter.dateStyle = .medium
                                dateFormatter.timeStyle = .short
                                return dateFormatter.string(from: timestamp)
                            } else {
                                return dateFormatter.string(from: timestamp)
                            }
                        }()
                        if !bleManager.isConnectedToPinetime {
                            Section {
                                // TODO: add support for "last seen 20 mins ago, at *location*"
                                Text("\(deviceManager.name) was last seen \(address.isEmpty ? "at \(date)" : "at \(address), at \(date)").")
                            }
                        }
                        Section(footer: bleManager.notifyCharacteristic == nil ? Text("\(deviceManager.name) must be connected to ping it.") : nil) {
                            Button(isPinging ? "Stop Pinging" : "Ping \(deviceManager.name)") {
                                isPinging.toggle()
                                
                                if isPinging {
                                    // Send this immediately, because otherwise there'll be a six second delay
                                    bleWriteManager.sendLostNotification()
                                    
                                    // Start timer for repeated notifications
                                    pingTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
                                        bleWriteManager.sendLostNotification()
                                    }
                                } else {
                                    pingTimer?.invalidate()
                                    pingTimer = nil
                                }
                            }
                            .disabled(bleManager.notifyCharacteristic == nil)
                        }
                        if !bleManager.isConnectedToPinetime {
                            Section {
                                Map(
                                    coordinateRegion: $region,
                                    annotationItems: [point]
                                ) { point in
                                    MapAnnotation(
                                        coordinate: CLLocationCoordinate2D(
                                            latitude: point.latitude,
                                            longitude: point.longitude
                                        )
                                    ) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.red)
                                    }
                                }
                                .frame(height: 400)
                                .id(mapId)
                                .listRowInsets(EdgeInsets())
                                Button("Get Directions") {
                                    openInMaps(to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                                }
                            }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Find Lost Device")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    guard let newPoint = chartManager.disconnectMapPoint() else { return }
                    
                    let coordinates = CLLocationCoordinate2D(latitude: newPoint.latitude, longitude: newPoint.longitude)
                    locationManager.getAddressFrom(coordinate: coordinates, addressComponents: [.name, .locality, .administrativeArea]) { address in
                        self.address = address ?? ""
                    }
                    
                    focusMap(on: newPoint)
                }
            }
            .navigationViewStyle(.stack)
        }
        .onReceive(rssiTimer) { _ in
            bleManager.infiniTime?.readRSSI()
        }
    }
}

#Preview {
    FindLostDeviceView()
}
