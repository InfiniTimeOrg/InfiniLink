//
//  InfiniLinkWidgetBundle.swift
//  WorkoutWidget
//
//  Created by Liam Willey on 9/9/26.
//

import WidgetKit
import SwiftUI

@main
struct InfiniLinkWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidgetLiveActivity()
        ChargingLiveActivity()
    }
}
