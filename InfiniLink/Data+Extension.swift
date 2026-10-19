//
//  Data+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/10/25.
//

import Foundation

extension FixedWidthInteger {
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian, Array.init)
    }
}

extension Array where Element == UInt8 {
    func littleEndianValue<T: FixedWidthInteger>(at offset: Int) -> T {
        self[offset..<offset + MemoryLayout<T>.size].reversed().reduce(0) { $0 << 8 | T($1) }
    }
}
