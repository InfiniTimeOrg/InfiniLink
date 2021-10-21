//
//  InfiniLinkApp.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

@main
struct InfiniLink: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
