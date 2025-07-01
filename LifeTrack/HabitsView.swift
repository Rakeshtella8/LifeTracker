import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \HabitCompletion.completionDate, order: .forward) private var completions: [HabitCompletion]
    @State private var showingAddSheet = false
    @State private var selectedHabit: Habit?
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if habits.isEmpty {
                    ContentUnavailableView("No Habits Yet", systemImage: "repeat", description: Text("Tap the + button to add your first habit."))
                } else {
                    // Habit Picker
                    Picker("Habit", selection: $selectedHabit) {
                        ForEach(habits) { habit in
                            Text(habit.name).tag(Optional(habit))
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear { if selectedHabit == nil { selectedHabit = habits.first } }

                    if let habit = selectedHabit {
                        // Calendar Heatmap
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(daysInCurrentMonth(), id: \.self) { day in
                                    let isComplete = isHabitComplete(habit: habit, date: day)
                                    Button(action: {
                                        toggleCompletion(habit: habit, date: day, isComplete: isComplete)
                                    }) {
                                        Text("\(Calendar.current.component(.day, from: day))")
                                            .frame(width: 36, height: 36)
                                            .background(isComplete ? Color.green : Color(.systemGray5))
                                            .foregroundColor(isComplete ? .white : .primary)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(Color.green, lineWidth: selectedDate.isSameDay(as: day) ? 2 : 0)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        // Analytics Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analytics").font(.headline)
                            HStack(spacing: 24) {
                                VStack(alignment: .leading) {
                                    Text("Current Streak")
                                        .font(.caption)
                                    Text("\(currentStreak(for: habit)) days")
                                        .fontWeight(.bold)
                                }
                                VStack(alignment: .leading) {
                                    Text("Longest Streak")
                                        .font(.caption)
                                    Text("\(longestStreak(for: habit)) days")
                                        .fontWeight(.bold)
                                }
                                VStack(alignment: .leading) {
                                    Text("Monthly Completion %")
                                        .font(.caption)
                                    Text("\(monthlyCompletion(for: habit))%")
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddSheet) { AddHabitView() }
        }
    }

    // MARK: - Calendar Helpers
    private func daysInCurrentMonth() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let range = calendar.range(of: .day, in: .month, for: today)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func isHabitComplete(habit: Habit, date: Date) -> Bool {
        completions.contains { $0.habit?.id == habit.id && $0.completionDate.isSameDay(as: date) }
    }

    private func toggleCompletion(habit: Habit, date: Date, isComplete: Bool) {
        if isComplete {
            if let completion = completions.first(where: { $0.habit?.id == habit.id && $0.completionDate.isSameDay(as: date) }) {
                modelContext.delete(completion)
            }
        } else {
            let newCompletion = HabitCompletion(completionDate: date)
            newCompletion.habit = habit
            modelContext.insert(newCompletion)
        }
    }

    // MARK: - Analytics
    private func currentStreak(for habit: Habit) -> Int {
        let days = daysInCurrentMonth().reversed()
        var streak = 0
        for day in days {
            if isHabitComplete(habit: habit, date: day) {
                streak += 1
            } else if day < Date().startOfDay {
                break
            }
        }
        return streak
    }

    private func longestStreak(for habit: Habit) -> Int {
        let days = daysInCurrentMonth()
        var maxStreak = 0
        var current = 0
        for day in days {
            if isHabitComplete(habit: habit, date: day) {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    private func monthlyCompletion(for habit: Habit) -> Int {
        let days = daysInCurrentMonth()
        let completed = days.filter { isHabitComplete(habit: habit, date: $0) }.count
        return days.isEmpty ? 0 : Int((Double(completed) / Double(days.count)) * 100)
    }
}

// MARK: - Date Helper
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

#Preview {
    HabitsView()
} 