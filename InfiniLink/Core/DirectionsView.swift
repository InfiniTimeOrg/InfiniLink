//
//  DirectionsView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI
import MapKit

struct DirectionsView: View {
    @ObservedObject var navigationController = NavigationController.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var deviceManager = DeviceManager.shared

    @StateObject private var mapSearch = MapSearch(resultTypes: [.address, .pointOfInterest])

    @State private var isDriving = false
    @State private var previewRoute: MKRoute?
    @State private var selectedItem: MKMapItem?

    private func select(_ completion: MKLocalSearchCompletion) {
        MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start { response, _ in
            guard let item = response?.mapItems.first else { return }

            selectedItem = item
            calculate()
        }
    }

    private func calculate() {
        guard let selectedItem else { return }

        previewRoute = nil
        navigationController.calculateRoute(to: selectedItem, transportType: isDriving ? .automobile : .walking) { route in
            previewRoute = route
        }
    }

    private func coordinates(of route: MKRoute) -> [CLLocationCoordinate2D] {
        let polyline = route.polyline
        return (0..<polyline.pointCount).map { polyline.points()[$0].coordinate }
    }

    var body: some View {
        ConnectedView(isReady: navigationController.isSupported || navigationController.isNavigating) {
            directions
        }
        .navigationTitle("Navigation")
        .onChange(of: isDriving) { _ in
            calculate()
        }
    }
    
    private var directions: some View {
        List {
            if navigationController.isNavigating, let route = navigationController.route {
                activeNavigation(route)
            } else {
                Section {
                    Picker("Travel By", selection: $isDriving) {
                        Text("Walking").tag(false)
                        Text("Driving").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                if let selectedItem {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedItem.name ?? NSLocalizedString("Destination", comment: ""))
                                .font(.headline)
                            if let route = previewRoute {
                                Text("\(NavigationController.distanceString(route.distance)) • \(Duration.seconds(route.expectedTravelTime).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))")
                                    .foregroundStyle(.gray)
                            } else if navigationController.isCalculating {
                                Text("Finding a route...")
                                    .foregroundStyle(.gray)
                            } else if let error = navigationController.error {
                                Text(error)
                                    .foregroundStyle(.red)
                            }
                        }
                        if let route = previewRoute {
                            RouteMapView(coordinates: coordinates(of: route))
                                .frame(height: 220)
                                .listRowInsets(EdgeInsets())
                            Button("Start Directions") {
                                navigationController.start(route: route)
                            }
                            .disabled(!bleManager.isConnectedToPinetime || !navigationController.isSupported)
                        }
                    } footer: {
                        Text("Open the Navigation app on \(deviceManager.name) to see your directions.")
                    }
                }
                if !mapSearch.locationResults.isEmpty {
                    Section("Results") {
                        ForEach(mapSearch.locationResults, id: \.self) { result in
                            Button {
                                select(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .foregroundStyle(Color.primary)
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $mapSearch.searchTerm, prompt: Text("Search for a place or address"))
    }

    @ViewBuilder
    private func activeNavigation(_ route: MKRoute) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if navigationController.hasArrived {
                    Label("You have arrived", systemImage: "flag.checkered")
                        .font(.title2.weight(.bold))
                } else if let step = navigationController.currentStep {
                    Text(NavigationController.distanceString(navigationController.distanceToManeuver))
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                    Text(step.instructions.isEmpty ? NSLocalizedString("Continue", comment: "") : step.instructions)
                        .font(.title3.weight(.medium))
                }
                Text(navigationController.destination?.name ?? "")
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
            RouteMapView(coordinates: coordinates(of: route))
                .frame(height: 260)
                .listRowInsets(EdgeInsets())
        }
        Section {
            Button(navigationController.hasArrived ? "Done" : "End Directions", role: .destructive) {
                navigationController.stop()
                previewRoute = nil
                selectedItem = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        DirectionsView()
    }
}
