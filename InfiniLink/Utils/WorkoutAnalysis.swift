//
//  WorkoutAnalysis.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation
import CoreLocation

struct HeartRateZone: Identifiable {
    let id: Int
    let range: ClosedRange<Double> // Fraction of max heart rate
    let duration: TimeInterval

    var name: String {
        String(format: NSLocalizedString("Zone %d", comment: ""), id)
    }
}

struct WorkoutSplit: Identifiable {
    let id: Int
    let duration: TimeInterval
    let isPartial: Bool
}

struct WorkoutAnalysis {
    // Longer gaps count as a pause
    static let maximumSampleGap: TimeInterval = 60

    static func maxHeartRate(age: Double) -> Double {
        return 220 - age
    }

    static func zones(for samples: [(date: Date, value: Double)], maxHeartRate: Double) -> [HeartRateZone] {
        let bounds: [ClosedRange<Double>] = [0.5...0.6, 0.6...0.7, 0.7...0.8, 0.8...0.9, 0.9...1.0]
        var durations = [TimeInterval](repeating: 0, count: bounds.count)

        for (current, next) in zip(samples, samples.dropFirst()) {
            let gap = next.date.timeIntervalSince(current.date)
            guard gap > 0, gap <= maximumSampleGap else { continue }

            let fraction = current.value / maxHeartRate
            if let index = bounds.lastIndex(where: { fraction >= $0.lowerBound }) {
                durations[index] += gap
            }
        }

        return bounds.indices.map { HeartRateZone(id: $0 + 1, range: bounds[$0], duration: durations[$0]) }
    }

    static func splits(for route: [RoutePoint], unitMeters: Double) -> [WorkoutSplit] {
        var splits = [WorkoutSplit]()
        var distance = 0.0
        var duration = 0.0

        for (current, next) in zip(route, route.dropFirst()) {
            let gap = next.timestamp.timeIntervalSince(current.timestamp)
            guard gap > 0, gap <= maximumSampleGap else { continue }

            let step = CLLocation(latitude: current.latitude, longitude: current.longitude).distance(from: CLLocation(latitude: next.latitude, longitude: next.longitude))
            distance += step
            duration += gap

            if distance >= unitMeters {
                let overshoot = (distance - unitMeters) / step
                splits.append(WorkoutSplit(id: splits.count + 1, duration: duration - gap * overshoot, isPartial: false))
                distance -= unitMeters
                duration = gap * overshoot
            }
        }

        if distance > unitMeters * 0.1 {
            // Scale the leftover so its pace is comparable to full splits
            splits.append(WorkoutSplit(id: splits.count + 1, duration: duration * unitMeters / distance, isPartial: true))
        }

        return splits
    }

    static func gpx(for route: [RoutePoint], name: String) -> String {
        let formatter = ISO8601DateFormatter()
        let escapedName = name
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        let points = route.map {
            "      <trkpt lat=\"\($0.latitude)\" lon=\"\($0.longitude)\"><time>\(formatter.string(from: $0.timestamp))</time></trkpt>"
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="InfiniLink" xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>\(escapedName)</name>
            <trkseg>
        \(points)
            </trkseg>
          </trk>
        </gpx>
        """
    }
}
