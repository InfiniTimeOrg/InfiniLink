//
//  String+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 1/8/25.
//

import Foundation

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
