//
//  DirectionsManager.swift
//  InfiniLink
//
//  Created by Liam Willey on 3/11/25.
//

import MapKit
import CoreLocation

class DirectionsManager: ObservableObject {
    @Published var currentRoute: MKRoute?
    @Published var distanceToNextStep: String = ""
    @Published var isLoading = false
    @Published var isNavigating = false
    @Published var steps: [MKRoute.Step] = []
    @Published var currentStepIndex = 0
    
    private let notificationManager = NotificationManager.shared
    private let bleWriteManager = BLEWriteManager()
    
    static let shared = DirectionsManager()

    func getDirections(to destination: CLLocationCoordinate2D) {
        guard !isNavigating else { return } // Prevent new routes mid-navigation
        guard let currentLocation = LocationManager.shared.location?.coordinate else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        self.isLoading = true
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error {
                print("Failed to get directions: \(error.localizedDescription)")
                self.isLoading = false
                return
            }

            guard let route = response?.routes.first else {
                self.isLoading = false
                return
            }
            
            self.currentRoute = route
            self.steps = route.steps.filter { !$0.instructions.isEmpty }
            self.currentStepIndex = 0
            self.isNavigating = true
            self.isLoading = false
            
            if !self.steps.isEmpty {
                self.advanceToNextStep()
            }
        }
    }

    func updateLocation(_ location: CLLocation) {
        guard currentStepIndex < steps.count else {
            sendArrivalMessage()
            return
        }

        let nextStep = steps[currentStepIndex]
        let stepLocation = nextStep.polyline.coordinate
        let currentDistance = location.distance(from: CLLocation(latitude: stepLocation.latitude, longitude: stepLocation.longitude))

        distanceToNextStep = convertedDistance(currentDistance)

        // Advance only if within 10 meters of the next step
        if currentDistance < 10 {
            advanceToNextStep()
        }
    }

    private func advanceToNextStep() {
        guard currentStepIndex < steps.count else {
            sendArrivalMessage()
            return
        }
        
        let currentStep = steps[currentStepIndex]
        let icon = determineTurnIcon(for: currentStep.instructions)
        
        // Calculate remaining progress
        var progress: UInt8 = 0
        if steps.count > 0 {
            progress = UInt8(Double(currentStepIndex) / Double(steps.count) * 100)
        }
        
        // Convert distance
        let distance = convertedDistance(currentStep.distance)
        
        bleWriteManager.writeNavigationUpdate(
            icon: icon,
            instructions: currentStep.instructions,
            distance: distance,
            progress: progress
        )

        self.currentStepIndex += 1
    }
    
    func convertedDistance(_ distance: CLLocationDistance) -> String {
        if PersonalizationController.shared.units == .imperial {
            return "\(String(format: "%.1f", distance / 3.280839895)) ft"
        } else {
            return "\(String(format: "%.1f", distance)) m"
        }
    }

    private func determineTurnIcon(for instructions: String) -> String {
        let lowercased = instructions.lowercased()
        
        // TODO: add more cases
        if lowercased.contains("turn left") {
            return "turn-left"
        }
        if lowercased.contains("turn right") {
            return "turn-right"
        }
        if lowercased.contains("merge") {
            return "merge"
        }
        if lowercased.contains("roundabout") {
            return "roundabout"
        }
        if lowercased.contains("take exit") {
            return "highway-exit"
        }
        if lowercased.contains("destination") || lowercased.contains("arrived") {
            return "flag"
        }
        return "fork"
    }

    private func sendArrivalMessage() {
        bleWriteManager.writeNavigationUpdate(
            icon: "flag",
            instructions: "You have arrived",
            distance: "",
            progress: 100
        )
        isNavigating = false
    }

    func cancelRoute() {
        self.currentRoute = nil
        self.steps.removeAll()
        self.currentStepIndex = 0
        self.isNavigating = false
        self.isLoading = false
    }
}
