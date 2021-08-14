//
//  Infini_iOSApp.swift
//  Infini-iOS
//
//  Created by xan-m on 8/5/21.
//

import SwiftUI

@main
struct Infini_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
				.environmentObject(PageSwitcher())
				.environmentObject(BLEManager())
        }
    }
}
