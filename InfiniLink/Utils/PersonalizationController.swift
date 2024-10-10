//
//  PersonalizationController.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

class PersonalizationController: ObservableObject {
    static let shared = PersonalizationController()
    
    @AppStorage("weight") var weight: Int?
    @AppStorage("age") var age: Int?
    @AppStorage("height") var height: Int?
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    // TODO: persist
    let pace: FitnessCalculator.Pace? = .average
    
    var isPersonalizationAvailable: Bool {
        !showSetupSheet && (weight == nil || height == nil || age == nil)
    }
}
