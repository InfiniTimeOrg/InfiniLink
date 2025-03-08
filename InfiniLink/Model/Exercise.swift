//
//  Exercise.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation

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
    
    init(id: String, name: String, icon: String, components: [ExerciseComponents], pace: Pace = .avgWalk) {
        self.id = id
        self.name = name
        self.icon = icon
        self.components = components
        self.pace = pace
    }
}
