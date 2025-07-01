//
//  ContentView.swift
//  LifeTrack
//
//  Created by rakesh tella on 01/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var tabManager = TabManager()
    @State private var showingAddSheet = false

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            DashboardView(tabManager: tabManager)
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            HabitsView()
                .tabItem { Label("Habits", systemImage: "repeat") }
                .tag(1)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
                .tag(2)

            BudgetView()
                .tabItem { Label("Budget", systemImage: "indianrupeesign.circle") }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
