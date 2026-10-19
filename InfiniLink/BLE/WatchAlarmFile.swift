//
//  WatchAlarmFile.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import Foundation

// alarm.dat is saved as raw bytes and only loaded if the version byte matches (1.15+)
struct WatchAlarmFile {
    static let path = "/.system/alarm.dat"
    static let directory = "/.system"
    static let currentVersion: UInt8 = 1

    private static let size = 12
    private static let hoursOffset = 1
    private static let minutesOffset = 2
    private static let recurrenceOffset = 4
    private static let enabledOffset = 8

    enum Recurrence: UInt32, CaseIterable {
        case none = 0
        case daily = 1
        case weekdays = 2
    }

    private(set) var data: Data

    init?(data: Data) {
        guard data.count >= Self.size, data[data.startIndex] == Self.currentVersion else { return nil }

        self.data = data
    }

    static var defaults: WatchAlarmFile {
        var bytes = [UInt8](repeating: 0, count: size)
        bytes[0] = currentVersion
        bytes[hoursOffset] = 7
        return WatchAlarmFile(data: Data(bytes))!
    }

    static func supported(onFirmware firmware: String) -> Bool {
        return firmware.compare("1.15.0", options: .numeric) != .orderedAscending
    }

    private func byte(_ offset: Int) -> UInt8 {
        return data[data.startIndex + offset]
    }
    private mutating func setByte(_ offset: Int, _ value: UInt8) {
        data[data.startIndex + offset] = value
    }

    var hours: UInt8 {
        get { byte(Self.hoursOffset) }
        set { setByte(Self.hoursOffset, newValue) }
    }
    var minutes: UInt8 {
        get { byte(Self.minutesOffset) }
        set { setByte(Self.minutesOffset, newValue) }
    }
    var recurrence: Recurrence {
        get {
            let raw = UInt32(byte(Self.recurrenceOffset)) | UInt32(byte(Self.recurrenceOffset + 1)) << 8 | UInt32(byte(Self.recurrenceOffset + 2)) << 16 | UInt32(byte(Self.recurrenceOffset + 3)) << 24
            return Recurrence(rawValue: raw) ?? .none
        }
        set {
            for index in 0..<4 {
                setByte(Self.recurrenceOffset + index, UInt8((newValue.rawValue >> (8 * UInt32(index))) & 0xFF))
            }
        }
    }
    var isEnabled: Bool {
        get { byte(Self.enabledOffset) != 0 }
        set { setByte(Self.enabledOffset, newValue ? 1 : 0) }
    }
}
