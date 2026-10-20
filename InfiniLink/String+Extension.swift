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
    
    var asciiSafe: String {
        // Transliterate all non-InfiniTime-readable characters from the string
        // including emojis, symbols, accents
        
        // Transform all emojis first
        let emojiTransformed = self.unicodeScalars.map { scalar -> String in
            if scalar.properties.isEmoji,
               let named = String(scalar).applyingTransform(.toUnicodeName, reverse: false) {
                // Get the emoji name inside \N{ }
                if let start = named.range(of: "\\N{"), let end = named.range(of: "}", range: start.upperBound..<named.endIndex) {
                    let name = named[start.upperBound..<end.lowerBound]
                    let shortcode = name
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "-")
                    return ":\(shortcode):"
                } else {
                    return named
                }
            } else {
                return String(scalar)
            }
        }.joined()
        
        let final = emojiTransformed
            .applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false) ?? emojiTransformed
        
        // Only keep ascii scalars
        let filteredScalars = final.unicodeScalars.filter { $0.isASCII }
        return String(String.UnicodeScalarView(filteredScalars))
    }
}
