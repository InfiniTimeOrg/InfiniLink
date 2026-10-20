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
    
    // Kept in state so view updates don't restart them
    @State private var rssiTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var hapticTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

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
    @State private var smoothedRSSI: Double?
    @State private var lastHaptic = Date.distantPast
    
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    private func updateSmoothedRSSI() {
        guard let rssi = bleManager.rssi, bleManager.isConnectedToPinetime else {
            smoothedRSSI = nil
            return
        }
        
        smoothedRSSI = (smoothedRSSI ?? Double(rssi)) * 0.6 + Double(rssi) * 0.4
    }
    
    private func playProximityHaptic() {
        guard let smoothedRSSI else { return }
        
        let closeness = min(max((smoothedRSSI + 100) / 40, 0), 1)
        guard Date().timeIntervalSince(lastHaptic) >= 1 - closeness * 0.85 else { return }
        
        lastHaptic = Date()
        hapticGenerator.impactOccurred(intensity: 0.5 + closeness * 0.5)
        hapticGenerator.prepare()
    }

    private func stopPinging() {
        pingTimer?.invalidate()
        pingTimer = nil
        isPinging = false
    }
    
    private func openInMaps(to coordinate: CLLocationCoordinate2D) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = deviceManager.name

        destination.openInMaps(launchOptions: nil)
    }
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                List {
                    VStack(spacing: 8) {
                        Image(systemName: bleManager.isConnectedToPinetime ? "checkmark.circle" : "xmark.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(bleManager.isConnectedToPinetime ? .green : .red)
                        Group {
                            if bleManager.isConnectedToPinetime {
                                Text("\(deviceManager.name) is connected")
                            } else {
                                Text("\(deviceManager.name) is disconnected")
                            }
                        }
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
                    let point = chartManager.disconnectMapPoint()
                    if let point, !bleManager.isConnectedToPinetime {
                        let timestamp = point.timestamp ?? Date()
                        let date = abs(timestamp.timeIntervalSinceNow) >= 60 * 60 * 24 ? timestamp.formatted(date: .abbreviated, time: .shortened) : timestamp.formatted(date: .omitted, time: .shortened)
                        
                        Section {
                            if address.isEmpty {
                                Text("\(deviceManager.name) was last seen at \(date).")
                            } else {
                                Text("\(deviceManager.name) was last seen at \(address), at \(date).")
                            }
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
                                stopPinging()
                            }
                        }
                        .disabled(bleManager.notifyCharacteristic == nil)
                    }
                    if let point, !bleManager.isConnectedToPinetime {
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
        }
        .onReceive(rssiTimer) { _ in
            bleManager.infiniTime?.readRSSI()
            updateSmoothedRSSI()
        }
        .onReceive(hapticTimer) { _ in
            playProximityHaptic()
        }
        .onDisappear {
            stopPinging()
        }
    }
}

#Preview {
    FindLostDeviceView()
}
