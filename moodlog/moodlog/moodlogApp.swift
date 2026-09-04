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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}