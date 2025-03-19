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
    enum Gender: Int {
        case male = 0
        case female = 1
    }
    
    @AppStorage("weight") var weight: Double?
    @AppStorage("height") var height: Double?
    @AppStorage("units") var units: Unit = .metric // TODO: change this to use system setting
    @AppStorage("gender") var gender: Gender = .male
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    var isPersonalizationAvailable: Bool {
        !showSetupSheet && (weight != nil || height != nil)
    }
    
    var calculatedWeight: Double {
        guard let weight = self.weight, weight > 0 else { return gender == .male ? 68.039 : 54.43 }
        
        if units == .imperial {
            // Convert from kg to lbs
            return weight * 2.205
        } else {
            return weight
        }
    }

    var calculatedHeight: Double {
        guard let height = self.height, height > 0 else { return gender == .male ? 175.26 : 162.56 }
        
        if units == .imperial {
            // Convert from cm to in
            return height / 2.54
        } else {
            return height
        }
    }
}
