//
//  LocationAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import CoreLocation
import JavaScriptCore

@objc protocol LocationAPIExports: JSExport {
    func getCurrent(_ priority: JSValue) -> [String: Any]?
    func getLast() -> [String: Any]?
    func addEventListener(_ event: String, _ callback: JSValue)
    func removeEventListener(_ event: String, _ callback: JSValue)
}

final class LocationAPI: NSObject, LocationAPIExports {
    private weak var runner: PluginRunner?

    init(runner: PluginRunner) {
        self.runner = runner
    }

    static func dictionary(from location: CLLocation) -> [String: Any] {
        return [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.verticalAccuracy >= 0 ? location.altitude : NSNull(),
            "accuracy": location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : NSNull()
        ]
    }

    // Kept for PinePartner, but iOS picks the accuracy
    func getCurrent(_ priority: JSValue) -> [String: Any]? {
        let semaphore = DispatchSemaphore(value: 0)
        var location: CLLocation?
        DispatchQueue.main.async {
            PluginLocationProvider.shared.requestLocation {
                location = $0
                semaphore.signal()
            }
        }

        guard semaphore.wait(timeout: .now() + 15) == .success, let location else {
            runner?.throwError("Couldn't get the current location. Is location access allowed?")
            return nil
        }
        return Self.dictionary(from: location)
    }

    func getLast() -> [String: Any]? {
        guard let location = DispatchQueue.main.sync(execute: { PluginLocationProvider.shared.lastLocation }) else { return nil }
        return Self.dictionary(from: location)
    }

    func addEventListener(_ event: String, _ callback: JSValue) {
        guard let runner else { return }
        guard event == "change" else {
            runner.throwError("Invalid event \(event)")
            return
        }

        runner.locationListeners.append(callback)
        if runner.locationListeners.count == 1 {
            DispatchQueue.main.async {
                PluginLocationProvider.shared.setSubscribed(true, for: runner)
            }
        }
    }

    func removeEventListener(_ event: String, _ callback: JSValue) {
        guard let runner, !runner.locationListeners.isEmpty else { return }

        runner.locationListeners.removeAll { $0.isEqual(to: callback) }
        if runner.locationListeners.isEmpty {
            DispatchQueue.main.async {
                PluginLocationProvider.shared.setSubscribed(false, for: runner)
            }
        }
    }
}

// Separate from LocationManager so plugins don't refetch the weather. Main queue only
final class PluginLocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = PluginLocationProvider()

    private let manager = CLLocationManager()
    private var pendingRequests: [(CLLocation?) -> Void] = []
    private var subscribers: Set<ObjectIdentifier> = []

    var lastLocation: CLLocation? {
        return manager.location
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        guard manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse else {
            completion(nil)
            return
        }
        // While updating for subscribers, the latest location is already current
        if !subscribers.isEmpty, let location = manager.location {
            completion(location)
            return
        }

        pendingRequests.append(completion)
        manager.requestLocation()
    }

    func setSubscribed(_ subscribed: Bool, for runner: PluginRunner) {
        let wasUpdating = !subscribers.isEmpty
        if subscribed {
            subscribers.insert(ObjectIdentifier(runner))
        } else {
            subscribers.remove(ObjectIdentifier(runner))
        }

        if !wasUpdating && !subscribers.isEmpty {
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        } else if wasUpdating && subscribers.isEmpty {
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
        }
    }

    private func finishRequests(with location: CLLocation?) {
        pendingRequests.forEach { $0(location) }
        pendingRequests = []
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        finishRequests(with: location)
        if !subscribers.isEmpty {
            PluginManager.shared.handleLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishRequests(with: manager.location)
    }
}
