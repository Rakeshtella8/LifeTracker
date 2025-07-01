import SwiftUI
import SwiftData

// --- Quote View ---
struct Quote {
    let text: String
    let author: String
}

struct QuoteView: View {
    private let quotes: [Quote] = [
        Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker"),
        Quote(text: "Well done is better than well said.", author: "Benjamin Franklin")
    ]

    private func getDailyQuote() -> Quote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let quoteIndex = (dayOfYear - 1) % quotes.count
        return quotes[quoteIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(getDailyQuote().text)\"")
                .font(.title2).fontWeight(.medium).italic()
            Text("- \(getDailyQuote().author)")
                .font(.subheadline).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding().background(Color(.systemGray6)).cornerRadius(12)
    }
}

// --- Main Dashboard View (Upgraded and Corrected) ---
struct DashboardView: View {
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \HabitCompletion.completionDate, order: .reverse) private var completions: [HabitCompletion]
    @Query(sort: \Task.dueDate, order: .forward) private var tasks: [Task]
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    // Helper: Get today's date range
    private var todayRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
        return start...end
    }
    // Helper: Get this month's date range
    private var monthRange: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        return calendar.dateInterval(of: .month, for: now)!
    }

    // Habits completed today
    private var habitsCompletedToday: Int {
        let todayCompletions = completions.filter { todayRange.contains($0.completionDate) }
        let completedHabitIDs = Set(todayCompletions.compactMap { $0.habit?.id })
        return completedHabitIDs.count
    }
    private var habitsTotal: Int { habits.count }
    private var habitsProgress: Double {
        habitsTotal == 0 ? 0 : Double(habitsCompletedToday) / Double(habitsTotal)
    }

    // Tasks completed today
    private var tasksCompletedToday: Int {
        tasks.filter { task in
            let isToday = todayRange.contains(task.dueDate)
            let isCompleted = task.status == .completed
            return isToday && isCompleted
        }.count
    }
    private var tasksTotalToday: Int {
        tasks.filter { todayRange.contains($0.dueDate) }.count
    }
    private var tasksProgress: Double {
        tasksTotalToday == 0 ? 0 : Double(tasksCompletedToday) / Double(tasksTotalToday)
    }

    // Budget chart logic
    private var totalBudget: Double {
        categories.reduce(0) { $0 + $1.budgetAmount }
    }
    private var totalSpentThisMonth: Double {
        expenses.filter { monthRange.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }
    private var budgetProgress: Double {
        totalBudget == 0 ? 0 : min(totalSpentThisMonth / totalBudget, 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    QuoteView()

                    Text("Today's Progress")
                        .font(.headline)
                        .padding(.top)

                    HStack(spacing: 24) {
                        DoughnutChartView(value: habitsProgress, title: "Habits", color: .blue)
                        DoughnutChartView(value: tasksProgress, title: "Tasks", color: .green)
                        DoughnutChartView(value: budgetProgress, title: "Budget", color: .red)
                    }
                    .frame(maxWidth: .infinity)

                    // Optionally, add more dashboard sections below
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
} 