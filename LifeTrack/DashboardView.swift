import SwiftUI
import SwiftData

// --- Quote Provider ---
class QuoteProvider {
    private let quotes: [Quote] = [
        Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker"),
        Quote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
        Quote(text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu"),
        Quote(text: "You reap what you sow.", author: "Indian Proverb"),
        Quote(text: "Little by little, one travels far.", author: "J.R.R. Tolkien"),
        Quote(text: "A single tree does not make a forest.", author: "Indian Proverb"),
        Quote(text: "Wisdom is wealth.", author: "Swahili Proverb"),
        Quote(text: "No one can whistle a symphony. It takes a whole orchestra to play it.", author: "H.E. Luccock"),
        Quote(text: "A book is like a garden carried in the pocket.", author: "Chinese Proverb"),
        Quote(text: "If you want to go fast, go alone. If you want to go far, go together.", author: "African Proverb"),
        Quote(text: "A diamond with a flaw is worth more than a pebble without imperfections.", author: "Indian Proverb"),
        Quote(text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb"),
        Quote(text: "A man is not honest simply because he never had a chance to steal.", author: "Indian Proverb"),
        Quote(text: "Courage is not the absence of fear, but the triumph over it.", author: "Nelson Mandela")
    ]
    func getRandomQuote() -> Quote {
        quotes.randomElement() ?? quotes.first!
    }
}

struct Quote {
    let text: String
    let author: String
}

struct QuoteView: View {
    let quote: Quote
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.title2).fontWeight(.medium).italic()
            Text("- \(quote.author)")
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
    @State private var quote: Quote = QuoteProvider().getRandomQuote()
    private let quoteProvider = QuoteProvider()

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
                    QuoteView(quote: quote)

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
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear {
                quote = quoteProvider.getRandomQuote()
            }
        }
    }
} 