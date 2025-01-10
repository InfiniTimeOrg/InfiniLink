//
//  String+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import Foundation

let testFlightLink = "https://testflight.apple.com/join/B3PY5HUV"
let appStoreLink = "https://apps.apple.com/us/app/infinilink/id1582318814"

extension String {
    func versionComponents() -> [Int] {
        let cleanString = self
            .lowercased()
            .replacingOccurrences(of: "v", with: "")
            .components(separatedBy: CharacterSet(charactersIn: "-."))
            .compactMap { Int($0) }
        return cleanString
    }
    
    /// Convert Hexadecimal String to Array<UInt>
    ///     "0123".hex                // [1, 35]
    ///     "aabbccdd 00112233".hex   // 170, 187, 204, 221, 0, 17, 34, 51]
    var hex : [UInt8] {
        return convertHex(self.unicodeScalars, i: self.unicodeScalars.startIndex, appendTo: [])
    }
    
    /// Convert Hexadecimal String to Data
    ///     "0123".hexData                    /// 0123
    ///     "aa bb cc dd 00 11 22 33".hexData /// aabbccdd 00112233
    var hexData : Data {
        return Data(convertHex(self.unicodeScalars, i: self.unicodeScalars.startIndex, appendTo: []))
    }
}

extension String: @retroactive Identifiable {
    public var id: UUID { UUID() }
}

fileprivate func convertHex(_ s: String.UnicodeScalarView, i: String.UnicodeScalarIndex, appendTo d: [UInt8]) -> [UInt8] {
    let skipChars = CharacterSet.whitespacesAndNewlines
    
    guard i != s.endIndex else { return d }
    
    let next1 = s.index(after: i)
    
    if skipChars.contains(s[i]) {
        return convertHex(s, i: next1, appendTo: d)
    } else {
        guard next1 != s.endIndex else { return d }
        let next2 = s.index(after: next1)
        
        let sub = String(s[i..<next2])
        
        guard let v = UInt8(sub, radix: 16) else { return d }
        
        return convertHex(s, i: next2, appendTo: d + [ v ])
    }
}
