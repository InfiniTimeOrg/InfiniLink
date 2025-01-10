//
//  Data+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/10/25.
//

import Foundation

extension Data {
    var hexString : String {
        return self.reduce("") { (a : String, v : UInt8) -> String in
            return a + String(format: "%02x", v)
        }
    }
}
