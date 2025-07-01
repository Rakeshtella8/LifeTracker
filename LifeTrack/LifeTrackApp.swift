//
//  LifeTrackApp.swift
//  LifeTrack
//
//  Created by rakesh tella on 01/07/25.
//

import SwiftUI
import SwiftData

@main
struct LifeTrackApp: App {
    // This creates the shared database container that the entire app will use.
    // This is the standard and correct way to set up SwiftData.
    let modelContainer: ModelContainer

    init() {
        do {
            // This defines which models are part of our database.
            let schema = Schema([
                Habit.self,
                HabitCompletion.self,
                Task.self,
                Expense.self,
                BudgetCategory.self,
                Item.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            // This creates the actual database file.
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If the database can't be created, the app will crash with an error.
            // This is important for debugging.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // This is the most critical line. It makes the database available to all views
        // so they can read and write data.
        .modelContainer(modelContainer)
    }
}
