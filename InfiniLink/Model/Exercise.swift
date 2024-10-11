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
}
