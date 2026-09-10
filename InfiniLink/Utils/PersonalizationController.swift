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
    enum EnergyUnit: Int {
        case kilocalorie = 0
        case kilojoule = 1
    }

    @AppStorage("weight") var weight: Double?
    @AppStorage("height") var height: Double?
    @AppStorage("age") var age: Int?
    @AppStorage("units") var units: Unit = .metric // TODO: change this to use system setting
    @AppStorage("gender") var gender: Gender = .male
    @AppStorage("energyUnit") var energyUnit: EnergyUnit = .kilocalorie
    
    @AppStorage("showSetupSheet") var showSetupSheet = true
    
    private let avgMaleWeight: Double = 68.039
    private let avgFemaleWeight: Double = 54.43
    private let avgMaleHeight: Double = 175.26
    private let avgFemaleHeight: Double = 162.56
    
    var isPersonalizationAvailable: Bool {
        !showSetupSheet && (weight != nil || height != nil)
    }
    
    var calculatedWeight: Double {
        var kg = gender == .male ? avgMaleWeight : avgFemaleWeight
        if let weight, weight > 0 { kg = weight }

        return units == .imperial ? kg * 2.205 : kg
    }

    var calculatedAge: Double {
        guard let age = self.age, age > 0 else { return 30 }

        return Double(age)
    }

    var calculatedWeightKg: Double {
        return units == .imperial ? calculatedWeight / 2.205 : calculatedWeight
    }

    var calculatedHeight: Double {
        var cm = gender == .male ? avgMaleHeight : avgFemaleHeight
        if let height, height > 0 { cm = height }

        return units == .imperial ? cm / 2.54 : cm
    }
}
