//
//  Infini_iOSApp.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/5/21.
//

import SwiftUI

@main
struct Infini_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
				.environmentObject(BLEManager())
				.environmentObject(DFU_Updater())
        }
    }
}
