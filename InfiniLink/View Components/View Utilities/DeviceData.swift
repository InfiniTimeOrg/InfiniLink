//
//  DeviceData.swift
//  InfiniLink
//
//  Created by John Stanley on 5/5/22.
//

import SwiftUI

class DeviceData: ObservableObject {
    
    @Published var chosenTheme: String {
        didSet {
            UserDefaults.standard.set(chosenTheme, forKey: "chosenTheme")
        }
    }
    
    @Published var allFavorites = ["Steps", "Heart", "Battery"]
    
    init() {
        self.chosenTheme = UserDefaults.standard.string(forKey: "chosenTheme") ?? "System Default"
    }
}


let appThemes: [String : ColorScheme] = ["Light":.light, "Dark":.dark]
