import SwiftUI
import SwiftData

struct HabitDetailView: View {
    let habit: Habit
    
    // This view will now use a more robust calendar implementation
    @State private var month: Date = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(habit.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Analytics Section
                HStack(spacing: 24) {
                    VStack {
                        Text("Current Streak").font(.caption)
                        Text("\(calculateStreak(for: habit).current) days").fontWeight(.bold)
                    }
                    VStack {
                        Text("Longest Streak").font(.caption)
                        Text("\(calculateStreak(for: habit).longest) days").fontWeight(.bold)
                    }
                    VStack {
                        Text("Total Completions").font(.caption)
                        Text("\(habit.completions?.count ?? 0)").fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // A more robust calendar view
                CalendarView(month: $month, habit: habit)
            }
            .padding()
        }
        .navigationTitle("Habit Details")
    }
    
    // This logic should be moved to a separate helper/viewmodel for cleaner code,
    // but is included here for simplicity.
    private func calculateStreak(for habit: Habit) -> (current: Int, longest: Int) {
        guard let completions = habit.completions, !completions.isEmpty else { return (0, 0) }
        
        let sortedDates = completions.map { $0.completionDate.startOfDay }.sorted().removingDuplicates()
        
        var currentStreak = 0
        var longestStreak = 0
        var streakStartDate = Date().startOfDay
        
        if let lastCompletion = sortedDates.last, lastCompletion.isSameDay(as: Date().startOfDay) || lastCompletion.isSameDay(as: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.startOfDay) {
            // Check for current streak
            for date in sortedDates.reversed() {
                if date.isSameDay(as: streakStartDate) {
                    currentStreak += 1
                    streakStartDate = Calendar.current.date(byAdding: .day, value: -1, to: streakStartDate)!
                } else {
                    break
                }
            }
        }
        
        // Check for longest streak
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

// A more robust Calendar View
struct CalendarView: View {
    @Binding var month: Date
    let habit: Habit
    
    private var weeks: [[Date]] {
        let calendar = Calendar.current
        let range = calendar.range(of: .weekOfMonth, in: .month, for: month)!
        return range.compactMap { week -> [Date]? in
            return calendar.dateInterval(of: .weekOfMonth, for: calendar.date(byAdding: .weekOfMonth, value: week - 1, to: month)!)?.start.daysOfWeek()
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { month = Calendar.current.date(byAdding: .month, value: -1, to: month)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(month, format: .dateTime.month().year())
                    .font(.headline)
                Spacer()
                Button(action: { month = Calendar.current.date(byAdding: .month, value: 1, to: month)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 10)
            
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \ .self) { day in
                    Text(day).frame(maxWidth: .infinity)
                }
            }
            
            ForEach(Array(weeks.enumerated()), id: \ .offset) { weekIndex, week in
                HStack {
                    ForEach(week, id: \ .self) { day in
                        Text("\(Calendar.current.component(.day, from: day))")
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(isCompleted(date: day) ? Color.green.opacity(0.3) : Color.clear)
                            )
                    }
                }
            }
        }
    }
    
    private func isCompleted(date: Date) -> Bool {
        habit.completions?.contains(where: { $0.completionDate.isSameDay(as: date) }) ?? false
    }
}

// Helper extensions
extension Date {
    func daysOfWeek() -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: self)!.start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
}

// MARK: - Date Helper
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
} 