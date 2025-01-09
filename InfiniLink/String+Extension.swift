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
}
