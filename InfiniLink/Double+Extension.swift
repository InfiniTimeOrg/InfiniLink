//
//  Double+Extension.swift
//  InfiniLink
//
//  Created by Liam Willey on 5/18/26.
//

import SwiftUI

extension Double {
    var batteryColor: Color {
        if self > 20 {
            return Color.green
        } else if self > 10 {
            return Color.orange
        } else if self == 0 {
            return Color.gray
        }
        return Color.red
    }
}
