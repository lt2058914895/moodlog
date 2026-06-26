//
//  moodlogApp.swift
//  moodlog
//
//  Created by deppon on 2026/6/25.
//

import SwiftUI

@main
struct moodlogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}