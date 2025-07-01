//
//  ContentView.swift
//  LifeTrack
//
//  Created by rakesh tella on 01/07/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showingAddSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            HabitsView()
                .tabItem { Label("Habits", systemImage: "repeat") }
                .tag(1)

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checkmark.circle") }
                .tag(2)

            BudgetView()
                .tabItem { Label("Budget", systemImage: "dollarsign.circle") }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}
