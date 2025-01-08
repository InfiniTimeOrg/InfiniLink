//
//  PersonalizationController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

class PersonalizationController: ObservableObject {
    static let shared = PersonalizationController()
    
    enum Unit: Int {
        case metric = 0
        case imperial = 1
    }
    
    @AppStorage("weight") var weight: Int?
    @AppStorage("age") var age: Int?
    @AppStorage("height") var height: Int?
    @AppStorage("units") var units: Unit = .metric
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    var isPersonalizationAvailable: Bool {
        !showSetupSheet && (weight != nil || height != nil || age != nil)
    }
}
