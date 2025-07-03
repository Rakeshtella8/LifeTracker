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
                        Text("\(habit.streak.current) days").fontWeight(.bold)
                    }
                    VStack {
                        Text("Longest Streak").font(.caption)
                        Text("\(habit.streak.longest) days").fontWeight(.bold)
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

                // The calendar view, now optimized
                CalendarView(month: $month, habit: habit)
            }
            .padding()
        }
        .navigationTitle("Habit Details")
    }
}

// A more robust Calendar View, optimized with .drawingGroup()
struct CalendarView: View {
    @Binding var month: Date
    let habit: Habit
    
    // The UI is restored to your original version's logic
    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        
        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingSpaces)
        let daysInMonth = calendar.range(of: .day, in: .month, for: month)!.count
        
        for dayIndex in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayIndex - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        let totalCells = (days.count + 6) / 7 * 7
        let trailingSpaces = totalCells - days.count
        if trailingSpaces > 0 {
            days.append(contentsOf: [Date?](repeating: nil, count: trailingSpaces))
        }
        
        // Chunk into weeks
        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
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
            
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        if let day = day {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(isCompleted(date: day) ? Color.green.opacity(0.3) : Color.clear)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(isCompleted(date: day) ? Color.green : Color.clear, lineWidth: 2)
                                )
                        } else {
                            Text("").frame(maxWidth: .infinity).padding(8)
                        }
                    }
                }
            }
        }
        // This is the key performance optimization for complex static views.
        .drawingGroup()
    }
    
    private func isCompleted(date: Date) -> Bool {
        habit.completions?.contains(where: { $0.completionDate.isSameDay(as: date) }) ?? false
    }
}
