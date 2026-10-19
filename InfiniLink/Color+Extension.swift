//
//  Color+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/5/24.
//

import SwiftUI

extension Color {
    static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
