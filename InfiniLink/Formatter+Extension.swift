//
//  Formatter+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/15/25.
//

import Foundation

extension Formatter {
    static let localizedDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        // This ensures the number is formatted for different locales, e.g 10,000 vs 10.000
        formatter.locale = Locale.current
        return formatter
    }()
}
