//
//  Exercise.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation
import HealthKit

enum ExerciseComponents {
    case heart
    case steps
}

struct Exercise: Identifiable {
    let id: String
    var name: String
    var icon: String
    let components: [ExerciseComponents]
    let pace: Pace
    let activityType: HKWorkoutActivityType
    
    init(id: String, name: String, icon: String, components: [ExerciseComponents], pace: Pace = .avgWalk, activityType: HKWorkoutActivityType = .running) {
        self.id = id
        self.name = name
        self.icon = icon
        self.components = components
        self.pace = pace
        self.activityType = activityType
    }
}
