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
    
    @AppStorage("weight") var weight: Double?
    @AppStorage("height") var height: Double?
    @AppStorage("units") var units: Unit = .metric // TODO: change this to use system setting
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    var isPersonalizationAvailable: Bool {
        !showSetupSheet && (weight != nil || height != nil)
    }
}
