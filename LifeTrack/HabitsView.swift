import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if habits.isEmpty {
                        ContentUnavailableView("No Habits Yet", systemImage: "repeat", description: Text("Tap the + button to add your first habit."))
                            .padding(.top, 20)
                    } else {
                        ForEach(habits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitRowView(habit: habit)
                            }
                            .buttonStyle(PlainButtonStyle())
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
        }
    }
}

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    var habit: Habit
    
    private var isCompletedToday: Bool {
        habit.completions?.contains(where: { $0.completionDate.isSameDay(as: Date()) }) ?? false
    }

    var body: some View {
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

