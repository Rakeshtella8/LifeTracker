import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedHabit: Habit?
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if habits.isEmpty {
                        ContentUnavailableView("No Habits Yet", systemImage: "repeat", description: Text("Tap the + button to add your first habit."))
                            .padding(.top, 20)
                    } else {
                        ForEach(habits) { habit in
                            HabitRowView(habit: habit) {
                                selectedHabit = habit
                                showingEditSheet = true
                            } onDelete: {
                                habitToDelete = habit
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddSheet) { AddHabitView() }
            .sheet(isPresented: $showingEditSheet) {
                if let habit = selectedHabit {
                    EditHabitView(habit: habit)
                }
            }
            .alert("Delete Habit", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let habit = habitToDelete {
                        deleteHabit(habit)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this habit? This action cannot be undone.")
            }
        }
    }

    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            modelContext.delete(habit)
            try? modelContext.save()
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                Text(habit.frequency)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                toggleHabitCompletion()
            }) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompletedToday ? .green : .gray)
                    .font(.title2)
            }
            
            OptionsMenuView(onEdit: onEdit, onDelete: onDelete)
        }
        .padding(.vertical, 4)
    }
    
    private var isCompletedToday: Bool {
        guard let lastCompleted = habit.lastCompleted else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }
    
    private func toggleHabitCompletion() {
        if isCompletedToday {
            // Remove today's completion
            habit.lastCompleted = nil
        } else {
            // Add today's completion
            habit.lastCompleted = Date()
            
            // Create a new completion record
            let completion = HabitCompletion(completionDate: Date())
            completion.habit = habit
            modelContext.insert(completion)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    HabitsView()
} 

