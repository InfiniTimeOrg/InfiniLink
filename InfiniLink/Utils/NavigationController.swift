//
//  NavigationController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation
import MapKit
import CoreLocation

class NavigationController: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = NavigationController()

    @Published private(set) var route: MKRoute?
    @Published private(set) var destination: MKMapItem?
    @Published private(set) var stepIndex = 0
    @Published private(set) var distanceToManeuver: CLLocationDistance = 0
    @Published private(set) var isNavigating = false
    @Published private(set) var isCalculating = false
    @Published private(set) var hasArrived = false
    @Published var error: String?

    private let locationManager = CLLocationManager()
    private let bleWriteManager = BLEWriteManager()

    private var transportType: MKDirectionsTransportType = .walking
    private var offRouteCount = 0
    private var lastWrite: (icon: String, narrative: String, distance: String, progress: UInt8)?
    private var lastWriteDate = Date.distantPast

    private let maneuverReachedDistance: CLLocationDistance = 20
    private let offRouteDistance: CLLocationDistance = 50

    var currentStep: MKRoute.Step? {
        guard let route, stepIndex < route.steps.count else { return nil }
        return route.steps[stepIndex]
    }

    var isSupported: Bool {
        let bleManager = BLEManager.shared
        return bleManager.navigationFlagsCharacteristic != nil && bleManager.navigationNarrativeCharacteristic != nil && bleManager.navigationDistanceCharacteristic != nil && bleManager.navigationProgressCharacteristic != nil
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .otherNavigation
    }

    func calculateRoute(to destination: MKMapItem, transportType: MKDirectionsTransportType, completion: ((MKRoute?) -> Void)? = nil) {
        self.destination = destination
        self.transportType = transportType
        isCalculating = true
        error = nil

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = transportType

        MKDirections(request: request).calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isCalculating = false
                if let error {
                    self?.error = error.localizedDescription
                    log("Error calculating route: \(error.localizedDescription)", caller: "NavigationController")
                }
                completion?(response?.routes.first)
            }
        }
    }

    func start(route: MKRoute) {
        self.route = route
        // First step is the start, so the first turn is the second step
        stepIndex = route.steps.count > 1 ? 1 : 0
        offRouteCount = 0
        hasArrived = false
        isNavigating = true
        lastWrite = nil

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false

        if isNavigating && !hasArrived {
            bleWriteManager.writeNavigationUpdate(icon: "flag", instructions: NSLocalizedString("Navigation ended", comment: ""), distance: "", progress: 0)
        }

        isNavigating = false
        route = nil
        destination = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0, let route, isNavigating, !hasArrived else { return }

        let steps = route.steps
        var maneuverPoint = coordinate(at: steps[stepIndex], start: true)
        distanceToManeuver = location.distance(from: CLLocation(latitude: maneuverPoint.latitude, longitude: maneuverPoint.longitude))

        if distanceToManeuver < maneuverReachedDistance {
            if stepIndex >= steps.count - 1 {
                arrive()
                return
            }
            stepIndex += 1
            maneuverPoint = coordinate(at: steps[stepIndex], start: true)
            distanceToManeuver = location.distance(from: CLLocation(latitude: maneuverPoint.latitude, longitude: maneuverPoint.longitude))
        }

        // Wait for a few readings off route so one bad GPS fix doesn't reroute
        if distance(from: location.coordinate, to: route.polyline) > offRouteDistance {
            offRouteCount += 1
            if offRouteCount >= 3, let destination, !isCalculating {
                offRouteCount = 0
                calculateRoute(to: destination, transportType: transportType) { [weak self] newRoute in
                    guard let self, let newRoute, self.isNavigating else { return }
                    self.start(route: newRoute)
                }
            }
        } else {
            offRouteCount = 0
        }

        writeUpdate(remaining: remainingDistance())
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Navigation location error: \(error.localizedDescription)", caller: "NavigationController")
    }

    private func arrive() {
        hasArrived = true
        distanceToManeuver = 0
        bleWriteManager.writeNavigationUpdate(icon: "arrive", instructions: NSLocalizedString("You have arrived", comment: ""), distance: "", progress: 100)

        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }

    private func remainingDistance() -> CLLocationDistance {
        guard let route else { return 0 }

        let later = route.steps.dropFirst(stepIndex + 1).reduce(0) { $0 + $1.distance }
        return distanceToManeuver + later
    }

    private func writeUpdate(remaining: CLLocationDistance) {
        guard let route, let step = currentStep else { return }

        let icon = stepIndex >= route.steps.count - 1 ? "arrive" : Self.icon(for: route.steps, at: stepIndex)
        let narrative = step.instructions.isEmpty ? NSLocalizedString("Continue", comment: "") : step.instructions
        let distance = Self.distanceString(distanceToManeuver)
        let progress = UInt8(max(0, min(100, 100 * (1 - remaining / max(route.distance, 1)))))

        // Skip writes that wouldn't change anything on the watch
        let changed = lastWrite?.icon != icon || lastWrite?.narrative != narrative || lastWrite?.distance != distance
        guard changed || Date().timeIntervalSince(lastWriteDate) > 15 else { return }

        bleWriteManager.writeNavigationUpdate(icon: icon, instructions: narrative, distance: distance, progress: progress)
        lastWrite = (icon, narrative, distance, progress)
        lastWriteDate = Date()
    }

    private func coordinate(at step: MKRoute.Step, start: Bool) -> CLLocationCoordinate2D {
        let polyline = step.polyline
        guard polyline.pointCount > 0 else { return polyline.coordinate }

        return polyline.points()[start ? 0 : polyline.pointCount - 1].coordinate
    }

    private func distance(from coordinate: CLLocationCoordinate2D, to polyline: MKPolyline) -> CLLocationDistance {
        let point = MKMapPoint(coordinate)
        let points = polyline.points()
        guard polyline.pointCount > 1 else { return polyline.pointCount == 1 ? point.distance(to: points[0]) : .infinity }

        var closest = CLLocationDistance.infinity
        for index in 0..<(polyline.pointCount - 1) {
            let a = points[index]
            let b = points[index + 1]
            let dx = b.x - a.x
            let dy = b.y - a.y
            let lengthSquared = dx * dx + dy * dy
            let t = lengthSquared > 0 ? max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared)) : 0
            closest = min(closest, point.distance(to: MKMapPoint(x: a.x + t * dx, y: a.y + t * dy)))
        }
        return closest
    }

    // Route steps don't say which way to turn, so we get it from the route's shape
    static func icon(for steps: [MKRoute.Step], at index: Int) -> String {
        guard index > 0, index < steps.count else { return "depart-straight" }

        let incoming = steps[index - 1].polyline
        let outgoing = steps[index].polyline
        guard incoming.pointCount > 1, outgoing.pointCount > 1 else { return "continue" }

        let inPoints = incoming.points()
        let outPoints = outgoing.points()
        let before = bearing(from: inPoints[incoming.pointCount - 2], to: inPoints[incoming.pointCount - 1])
        let after = bearing(from: outPoints[0], to: outPoints[1])

        var delta = after - before
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }

        let side = delta > 0 ? "right" : "left"
        switch abs(delta) {
        case ..<20:
            return "continue-straight"
        case ..<45:
            return "turn-slight-\(side)"
        case ..<135:
            return "turn-\(side)"
        case ..<170:
            return "turn-sharp-\(side)"
        default:
            return "uturn"
        }
    }

    // Map points grow east in x and south in y, so this is a compass bearing
    private static func bearing(from a: MKMapPoint, to b: MKMapPoint) -> Double {
        return atan2(b.x - a.x, a.y - b.y) * 180 / .pi
    }

    static func distanceString(_ meters: CLLocationDistance) -> String {
        if PersonalizationController.shared.units == .imperial {
            let feet = meters * 3.281
            if feet < 528 {
                return "\(Int((feet / 10).rounded() * 10)) ft"
            }
            return String(format: "%.1f mi", meters / 1609.344)
        }

        if meters < 1000 {
            return "\(Int((meters / 10).rounded() * 10)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
