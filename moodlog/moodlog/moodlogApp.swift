//
//  moodlogApp.swift
//  moodlog
//
//  Created by lt on 2026/6/23.
//

import SwiftUI
import CoreData

@main
struct moodlogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
