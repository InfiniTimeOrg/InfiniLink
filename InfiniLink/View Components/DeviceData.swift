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
    @Published var chosenWeatherMode: String {
        didSet {
            UserDefaults.standard.set(chosenWeatherMode, forKey: "chosenWeatherMode")
        }
    }
    @Published var allFavorites = ["Steps", "Heart", "Battery"]
    
    init() {
        self.chosenTheme = UserDefaults.standard.string(forKey: "chosenTheme") ?? "System"
        self.chosenWeatherMode = UserDefaults.standard.string(forKey: "chosenWeatherMode") ?? "System"
    }
}


let appThemes: [String : ColorScheme] = ["Light":.light, "Dark":.dark]
