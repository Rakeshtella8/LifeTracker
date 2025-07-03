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
                // You can add navigation logic here later
                // Example: NavigationLink("View All", destination: TasksViewContainer())
            }
            
            if todayTasks.isEmpty {
                Text("No tasks for today. Great job!")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
                // NavigationLink("View All", destination: HabitsView())
            }
            
            if todayHabits.isEmpty {
                Text("No daily habits tracked.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
                 // NavigationLink("View All", destination: BudgetView())
            }
            
            if recentExpenses.isEmpty {
                Text("No recent expenses recorded.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
                Text("No budgets set up. Go to the Budget tab to create one.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
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
        tasks.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: selectedDate) }
    }
    
    private var todayHabits: [Habit] {
        habits.filter { $0.frequency == "daily" && $0.isActive }
    }
    
    private var recentExpenses: [ExpenseModel] {
        expenses.prefix(5).map { $0 }
    }
    
    private var totalTasksToday: Int {
        todayTasks.count
    }
    
    private var completedTasksToday: Int {
        todayTasks.filter { $0.status == .completed }.count
    }
    
    private var totalHabitsToday: Int {
        todayHabits.count
    }
    
    private var completedHabitsToday: Int {
        todayHabits.filter { habit in
            habit.completions?.contains { Calendar.current.isDate($0.completionDate, inSameDayAs: selectedDate) } ?? false
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
    @Bindable var task: Task

    var body: some View {
        HStack {
            Button(action: {
                task.status = (task.status == .completed) ? .notStarted : .completed
            }) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == .completed ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())

            Text(task.title)
                .strikethrough(task.status == .completed, color: .secondary)

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
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
            
            Button(action: toggleCompletion) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompletedToday() ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func isCompletedToday() -> Bool {
        habit.completions?.contains { $0.completionDate.isSameDay(as: Date()) } ?? false
    }
    
    private func toggleCompletion() {
        let today = Date().startOfDay
        if let completion = habit.completions?.first(where: { $0.completionDate.isSameDay(as: today) }) {
            modelContext.delete(completion)
        } else {
            let newCompletion = HabitCompletion(completionDate: today)
            newCompletion.habit = habit // Correctly associate the completion with the habit
            modelContext.insert(newCompletion)
        }
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
