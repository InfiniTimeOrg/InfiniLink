//
//  WorkoutRouteRecorder.swift
//  InfiniLink
//
//  Created by Liam Willey on 9/9/26.
//

import Foundation
import CoreLocation

struct RoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class WorkoutRouteRecorder: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WorkoutRouteRecorder()

    @Published private(set) var points: [RoutePoint] = []
    @Published private(set) var distance: CLLocationDistance = 0

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isRunning = false
    private var recordsRoute = false

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
    }

    // recordingRoute false keeps location updates flowing to hold background execution open, without storing anything
    func start(recordingRoute: Bool, resuming existing: [RoutePoint] = []) {
        points = recordingRoute ? existing : []
        distance = recordingRoute ? Self.totalDistance(of: existing) : 0
        lastLocation = nil
        isRunning = true
        recordsRoute = recordingRoute

        manager.desiredAccuracy = recordingRoute ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyHundredMeters
        manager.distanceFilter = recordingRoute ? kCLDistanceFilterNone : 100

        if manager.authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func stop() {
        isRunning = false
        recordsRoute = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func reset() {
        points = []
        distance = 0
        lastLocation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRunning, recordsRoute else { return }

        for location in locations {
            guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50 else { continue }

            if let last = lastLocation {
                let step = location.distance(from: last)
                // Ignore gps jitter while we're not moving
                guard step >= 10 else { continue }
                distance += step
            }

            lastLocation = location
            points.append(RoutePoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, timestamp: location.timestamp))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("Workout route error: \(error.localizedDescription)", caller: "WorkoutRouteRecorder")
    }

    static func totalDistance(of points: [RoutePoint]) -> CLLocationDistance {
        guard points.count > 1 else { return 0 }

        var total = 0.0
        for index in 1..<points.count {
            let start = CLLocation(latitude: points[index - 1].latitude, longitude: points[index - 1].longitude)
            let end = CLLocation(latitude: points[index].latitude, longitude: points[index].longitude)
            total += end.distance(from: start)
        }

        return total
    }
}
