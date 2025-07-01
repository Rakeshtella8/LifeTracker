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
    @Environment(\.modelContext) private var modelContext
    var habit: Habit
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    private var isCompletedToday: Bool {
        habit.completions?.contains(where: { $0.completionDate.isSameDay(as: Date()) }) ?? false
    }

    var body: some View {
        NavigationLink(destination: HabitDetailView(habit: habit)) {
            HStack(spacing: 15) {
                HabitPlantView(streak: calculateStreak(for: habit).current)
                
                VStack(alignment: .leading) {
                    Text(habit.name)
                        .font(.headline)
                    Text("Current Streak: \(calculateStreak(for: habit).current) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: toggleCompletion) {
                    Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(isCompletedToday ? .green : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                OptionsMenuView(onEdit: onEdit, onDelete: onDelete)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleCompletion() {
        if isCompletedToday {
            if let completion = habit.completions?.first(where: { $0.completionDate.isSameDay(as: Date()) }) {
                modelContext.delete(completion)
                try? modelContext.save()
            }
        } else {
            let newCompletion = HabitCompletion(completionDate: Date())
            newCompletion.habit = habit
            modelContext.insert(newCompletion)
            try? modelContext.save()
        }
    }
    
    private func calculateStreak(for habit: Habit) -> (current: Int, longest: Int) {
        guard let completions = habit.completions, !completions.isEmpty else { return (0, 0) }
        let sortedDates = completions.map { $0.completionDate.startOfDay }.sorted().removingDuplicates()
        var currentStreak = 0
        var longestStreak = 0
        var streakStartDate = Date().startOfDay
        if let lastCompletion = sortedDates.last, lastCompletion.isSameDay(as: Date().startOfDay) || lastCompletion.isSameDay(as: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.startOfDay) {
            for date in sortedDates.reversed() {
                if date.isSameDay(as: streakStartDate) {
                    currentStreak += 1
                    streakStartDate = Calendar.current.date(byAdding: .day, value: -1, to: streakStartDate)!
                } else {
                    break
                }
            }
        }
        var currentLongest = 0
        for i in 0..<sortedDates.count {
            if i > 0 && sortedDates[i] == Calendar.current.date(byAdding: .day, value: 1, to: sortedDates[i-1]) {
                currentLongest += 1
            } else {
                currentLongest = 1
            }
            if currentLongest > longestStreak {
                longestStreak = currentLongest
            }
        }
        return (currentStreak, longestStreak)
    }
}

#Preview {
    HabitsView()
} 

