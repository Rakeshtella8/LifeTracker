import SwiftUI
import SwiftData
import Charts

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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.dueDate, order: .reverse) private var tasks: [Task]
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @Query(sort: \ExpenseModel.date, order: .reverse) private var expenses: [ExpenseModel]
    @Query(sort: \BudgetCategory.name) private var budgetCategories: [BudgetCategory]
    
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var showingAddHabit = false
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    welcomeSection
                    quickStatsSection
                    todayTasksSection
                    todayHabitsSection
                    recentExpensesSection
                    budgetOverviewSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Task") { showingAddTask = true }
                        Button("Add Habit") { showingAddHabit = true }
                        Button("Add Expense") { showingAddExpense = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title)
                .bold()
            Text("Here's your life overview for today")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Tasks", value: "\(completedTasksToday)/\(totalTasksToday)", color: .blue)
            StatCard(title: "Habits", value: "\(completedHabitsToday)/\(totalHabitsToday)", color: .green)
            StatCard(title: "Spent", value: String(format: "₹%.0f", totalSpentToday), color: .red)
        }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to tasks view
                }
                .font(.subheadline)
            }
            
            if todayTasks.isEmpty {
                Text("No tasks for today")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayTasks.prefix(3)) { task in
                        DashboardTaskRowView(task: task)
                    }
                }
            }
        }
    }
    
    private var todayHabitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Habits")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to habits view
                }
                .font(.subheadline)
            }
            
            if todayHabits.isEmpty {
                Text("No habits for today")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayHabits.prefix(3)) { habit in
                        DashboardHabitRowView(habit: habit)
                    }
                }
            }
        }
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Expenses")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to budget view
                }
                .font(.subheadline)
            }
            
            if recentExpenses.isEmpty {
                Text("No recent expenses")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentExpenses.prefix(3)) { expense in
                        ExpenseRowView(expense: expense)
                    }
                }
            }
        }
    }
    
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Overview")
                .font(.headline)
            
            if budgetCategories.isEmpty {
                Text("No budget categories set up")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            } else {
                VStack(spacing: 8) {
                    ForEach(budgetCategories.prefix(3)) { category in
                        BudgetProgressView(category: category, expenses: expensesForCategory(category))
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var todayTasks: [Task] {
        tasks.filter { task in
            return Calendar.current.isDate(task.dueDate, inSameDayAs: selectedDate)
        }
    }
    
    private var todayHabits: [Habit] {
        habits.filter { habit in
            habit.isActive && habit.frequency == "daily"
        }
    }
    
    private var recentExpenses: [ExpenseModel] {
        expenses.prefix(5).map { $0 }
    }
    
    private var totalTasksToday: Int {
        todayTasks.count
    }
    
    private var completedTasksToday: Int {
        todayTasks.filter { $0.isCompleted }.count
    }
    
    private var totalHabitsToday: Int {
        todayHabits.count
    }
    
    private var completedHabitsToday: Int {
        todayHabits.filter { habit in
            if let lastCompleted = habit.lastCompleted {
                return Calendar.current.isDate(lastCompleted, inSameDayAs: selectedDate)
            }
            return false
        }.count
    }
    
    private var totalSpentToday: Double {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func expensesForCategory(_ category: BudgetCategory) -> [ExpenseModel] {
        expenses.filter { $0.category == category.name }
    }
}

struct DashboardTaskRowView: View {
    let task: Task
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            Button(action: {
                task.isCompleted.toggle()
                try? modelContext.save()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())

            Text(task.title)
                .strikethrough(task.isCompleted)

            Spacer()
        }
    }
}

struct DashboardHabitRowView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    
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

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BudgetProgressView: View {
    let category: BudgetCategory
    let expenses: [ExpenseModel]
    
    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        guard category.budgetAmount > 0 else { return 0 }
        return min(totalSpent / category.budgetAmount, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("₹\(totalSpent, specifier: "%.0f") / ₹\(category.budgetAmount, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progress > 0.8 ? .red : .blue))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Task.self, Habit.self, ExpenseModel.self, BudgetCategory.self], inMemory: true)
} 