//
//  SetTime.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/29/21.
//
//

import Foundation

enum SetTime {
    // Current Time Service layout: year, month, day, hour, minute, second, weekday (Monday = 1), 1/256ths of a second, adjust reason
    static func currentTime() -> Data {
        let components = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday, .nanosecond], from: Date())
        let weekday = (components.weekday! + 5) % 7 + 1
        let fractions = components.nanosecond! * 256 / 1_000_000_000
        
        var data = Data(UInt16(components.year!).littleEndianBytes)
        data.append(contentsOf: [components.month!, components.day!, components.hour!, components.minute!, components.second!, weekday, fractions, 0].map { UInt8($0) })
        return data
    }
}
