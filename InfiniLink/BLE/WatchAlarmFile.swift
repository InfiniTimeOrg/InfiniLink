//
//  WatchAlarmFile.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation

struct WatchAlarmFile { // alarm.dat is an array of raw alarm structs, starting with the format version
    static let path = "/.system/alarm.dat"
    static let directory = "/.system"

    private static let stride = 12
    private static let hoursOffset = 1
    private static let minutesOffset = 2
    private static let recurrenceOffset = 4
    private static let enabledOffset = 8

    enum Recurrence: UInt32, CaseIterable {
        case none = 0
        case daily = 1
        case weekdays = 2
    }

    struct Alarm {
        var hours: UInt8
        var minutes: UInt8
        var recurrence: Recurrence
        var isEnabled: Bool
    }

    private(set) var data: Data

    var count: Int {
        Self.alarmCount(forVersion: data[data.startIndex]) ?? 0
    }

    init?(data: Data) {
        guard let version = data.first, let count = Self.alarmCount(forVersion: version), data.count >= count * Self.stride else { return nil }

        self.data = data
    }

    static var defaults: WatchAlarmFile {
        var bytes = [UInt8](repeating: 0, count: stride)
        bytes[0] = 1
        bytes[hoursOffset] = 7
        return WatchAlarmFile(data: Data(bytes))!
    }

    static func supported(onFirmware firmware: String) -> Bool {
        return firmware.compare("1.15.0", options: .numeric) != .orderedAscending
    }

    static func alarmCount(forVersion version: UInt8) -> Int? {
        switch version {
        case 1: return 1
        case 2: return 4
        default: return nil
        }
    }

    private func byte(_ offset: Int) -> UInt8 {
        return data[data.startIndex + offset]
    }
    private mutating func setByte(_ offset: Int, _ value: UInt8) {
        data[data.startIndex + offset] = value
    }

    // nil if the alarm's bytes don't make sense
    subscript(index: Int) -> Alarm? {
        get {
            let base = index * Self.stride
            let raw = (0..<4).reduce(UInt32(0)) { $0 | UInt32(byte(base + Self.recurrenceOffset + $1)) << (8 * UInt32($1)) }
            guard byte(base) == byte(0), byte(base + Self.hoursOffset) < 24, byte(base + Self.minutesOffset) < 60, let recurrence = Recurrence(rawValue: raw) else { return nil }

            return Alarm(hours: byte(base + Self.hoursOffset), minutes: byte(base + Self.minutesOffset), recurrence: recurrence, isEnabled: byte(base + Self.enabledOffset) != 0)
        }
        set {
            guard let newValue else { return }

            let base = index * Self.stride
            setByte(base + Self.hoursOffset, newValue.hours)
            setByte(base + Self.minutesOffset, newValue.minutes)
            for offset in 0..<4 {
                setByte(base + Self.recurrenceOffset + offset, UInt8((newValue.recurrence.rawValue >> (8 * UInt32(offset))) & 0xFF))
            }
            setByte(base + Self.enabledOffset, newValue.isEnabled ? 1 : 0)
        }
    }
}
