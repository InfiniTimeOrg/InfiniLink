//
//  FindLostDeviceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/31/25.
//

import SwiftUI
import MapKit

struct FindLostDeviceView: View {
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var bleManager = BLEManager.shared
    @ObservedObject private var chartManager = ChartManager.shared
    @ObservedObject private var deviceManager = DeviceManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    
    private let bleWriteManager = BLEWriteManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
    )
    @State private var mapId = UUID()
    @State private var address = ""
    @State private var pingTimer: Timer? = nil
    @State private var isPinging = false
    
    private func setRegion(_ points: [DisconnectMapPoint]? = nil) {
        let delta = 0.02
        if let last = (points ?? chartManager.disconnectMapPoints()).last {
            print(last)
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude),
                span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            )
            // Force the map to refresh
            self.mapId = UUID()
        } else {
            // If there aren't any points, show the current location
            guard let location = locationManager.location else { return }
            
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            )
        }
    }
    private func openInMaps(to coordinate: CLLocationCoordinate2D) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = deviceManager.name

        destination.openInMaps(launchOptions: nil)
    }
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                List {
                    Section {
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
                    }
                    if let last = chartManager.disconnectMapPoints().last {
                        let date = {
                            let timestamp = last.timestamp ?? Date()
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
                        Section {
                            // TODO: add support for "last seen 20 mins ago, at *location*"
                            Text("\(deviceManager.name) was last seen \(address.isEmpty ? "at \(date)" : "at \(address), at \(date)").")
                        }
                        .onAppear {
                            locationManager.getAddressFrom(coordinate: CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude), addressComponents: [.name, .locality, .administrativeArea]) { address in
                                self.address = address ?? ""
                            }
                        }
                    }
                    if !chartManager.disconnectMapPoints().isEmpty {
                        Section {
                            Map(
                                coordinateRegion: $region,
                                annotationItems: chartManager.disconnectMapPoints() // TODO: show just one for now
                            ) { point in
                                MapPin(coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude), tint: .red)
                            }
                            .frame(height: 400)
                            .id(mapId)
                            .listRowInsets(EdgeInsets())
                            Button("Get Directions") {
                                guard let point = chartManager.disconnectMapPoints().last else { return }
                                
                                openInMaps(to: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                            }
                        }
                    }
                    Section(footer: bleManager.notifyCharacteristic == nil ? Text("\(deviceManager.name) must be connected to ping it.") : nil) {
                        Button(isPinging ? "Stop Pinging" : "Ping \(deviceManager.name)") {
                            isPinging.toggle()
                            
                            if isPinging {
                                // Send this immediately, because otherwise there'll be a five second delay
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
                    setRegion()
                }
                .onChange(of: chartManager.disconnectMapPoints()) { points in
                    setRegion(points)
                }
            }
            .navigationViewStyle(.stack)
        }
    }
}

#Preview {
    FindLostDeviceView()
}
