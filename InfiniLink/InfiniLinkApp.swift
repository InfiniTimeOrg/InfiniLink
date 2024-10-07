//
//  InfiniLinkApp.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

@main
struct InfiniLink: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    HealthKitManager.shared.requestAuthorization()
                }
        }
    }
}
