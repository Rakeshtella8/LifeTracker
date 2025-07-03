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
    let modelContainer: ModelContainer?
    @State private var showingInitializationError = false
    @State private var initializationError: Error?

    init() {
        do {
            // This defines which models are part of our database.
            modelContainer = try ModelContainer(
                for: Task.self, Habit.self, ExpenseModel.self, BudgetCategory.self, PaymentReminder.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            // Store the error to show to the user instead of crashing
            print("Could not initialize ModelContainer: \(error)")
            initializationError = error
            modelContainer = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
            } else {
                DatabaseErrorView(error: initializationError)
            }
        }
    }
}

struct DatabaseErrorView: View {
    let error: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Database Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unable to initialize the app database. Please restart the app or contact support if the problem persists.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Button("Retry") {
                // Force restart the app
                exit(0)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
