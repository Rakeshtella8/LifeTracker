import SwiftUI
import SwiftData
import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

enum BudgetPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case custom = "Custom"
    var id: String { self.rawValue }
}

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingAddSheet = false
    @State private var showingBudgetSetup = false
    @State private var showingEditSheet = false
    @State private var selectedExpense: Expense?
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    @State private var selectedPeriod: BudgetPeriod = .today
    @State private var selectedDay: Date = Date()
    @State private var showDayExpenses: Bool = false
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: Expense?
    
    // Helper: Calculate amount spent in a category for the selected range
    private func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Helper: Financial Insights
    private var insights: [String] {
        var tips: [String] = []
        for category in categories {
            let spentAmount = spent(for: category)
            let percent = category.budgetAmount == 0 ? 0 : Int((spentAmount / category.budgetAmount) * 100)
            if percent >= 80 {
                tips.append("You are \(percent)% of the way to your '\(category.name)' budget for this period.")
            }
        }
        if let highest = categories.max(by: { spent(for: $0) < spent(for: $1) }), spent(for: highest) > 0 {
            tips.append("Your highest spending category is '\(highest.name)'.")
        }
        return tips.isEmpty ? ["You're managing your budget well!"] : tips
    }
    
    // Pie chart data
    private var pieData: [ChartData] {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        return grouped.map { (key, value) in ChartData(category: key, amount: value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.amount > 0 }
    }
    
    // Recent transactions
    private var recentTransactions: [Expense] {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .prefix(10)
            .map { $0 }
    }
    
    // Expenses for selected day
    private var dayExpenses: [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(BudgetPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPeriod) { updateDatesForPeriod() }
                    // Calendar
                    DatePicker("Select Day", selection: $selectedDay, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDay) {
                            showDayExpenses = true
                            startDate = Calendar.current.startOfDay(for: selectedDay)
                            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!.addingTimeInterval(-1)
                        }
                        .padding(.bottom, 8)
                    // Custom Range
                    if selectedPeriod == .custom {
                        HStack {
                            DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            DatePicker("End", selection: $endDate, displayedComponents: .date)
                        }
                    }
                    HStack {
                        Text("Budgets").font(.title2).bold()
                        Spacer()
                        Button("Setup Budgets") { showingBudgetSetup = true }
                            .font(.subheadline)
                    }
                    if categories.isEmpty {
                        Text("No budget categories set up yet.")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(categories) { category in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(category.name).fontWeight(.semibold)
                                        Spacer()
                                        Text("₹\(spent(for: category), specifier: "%.2f") / ₹\(category.budgetAmount, specifier: "%.2f")")
                                            .font(.caption)
                                    }
                                    ProgressView(value: min(spent(for: category) / max(category.budgetAmount, 1), 1.0))
                                        .accentColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    Divider()
                    // Pie Chart
                    if !pieData.isEmpty {
                        Chart {
                            ForEach(pieData) { item in
                                SectorMark(
                                    angle: .value("Amount", item.amount),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                            }
                        }
                        .frame(height: 180)
                        .padding(.vertical, 8)
                    }
                    Text("Financial Insights").font(.headline)
                    ForEach(insights, id: \.self) { tip in
                        Text(tip).font(.subheadline).foregroundColor(.secondary)
                    }
                    Divider()
                    if showDayExpenses {
                        Text("Expenses for \(selectedDay, format: .dateTime.year().month().day())").font(.headline)
                        if dayExpenses.isEmpty {
                            Text("No expenses for this day.").foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(dayExpenses) { expense in
                                    ExpenseRowView(expense: expense) {
                                        selectedExpense = expense
                                        showingEditSheet = true
                                    } onDelete: {
                                        expenseToDelete = expense
                                        showingDeleteAlert = true
                                    }
                                }
                            }
                        }
                        Divider()
                    }
                    Text("Recent Transactions").font(.headline)
                    if recentTransactions.isEmpty {
                        Text("No transactions in this period.")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentTransactions) { expense in
                                ExpenseRowView(expense: expense) {
                                    selectedExpense = expense
                                    showingEditSheet = true
                                } onDelete: {
                                    expenseToDelete = expense
                                    showingDeleteAlert = true
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
            .sheet(isPresented: $showingBudgetSetup) {
                BudgetSetupView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddExpenseView()
            }
            .sheet(isPresented: $showingEditSheet) {
                if let expense = selectedExpense {
                    EditExpenseView(expense: expense)
                }
            }
            .alert("Delete Expense", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let expense = expenseToDelete {
                        deleteExpense(expense)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.")
            }
        }
    }
    
    private func updateDatesForPeriod() {
        let calendar = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .today:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!.addingTimeInterval(-1)
        case .week:
            let week = calendar.dateInterval(of: .weekOfYear, for: now)!
            startDate = week.start
            endDate = week.end.addingTimeInterval(-1)
        case .month:
            let month = calendar.dateInterval(of: .month, for: now)!
            startDate = month.start
            endDate = month.end.addingTimeInterval(-1)
        case .custom:
            // Don't change start/end, user will pick
            break
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
        }
    }
}

struct BudgetSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @State private var newCategoryName: String = ""
    @State private var newBudgetAmount: String = ""
    @State private var selectedCategory: String = "Food"
    @State private var customCategoryName: String = ""
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: BudgetCategory?
    
    let categoryOptions = ["Food", "Transport", "Shopping", "Utilities", "Miscellaneous", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoryOptions, id: \.self) { category in
                            Text(category)
                        }
                    }
                    
                    if selectedCategory == "Other" {
                        TextField("Custom Category Name", text: $customCategoryName)
                    }
                    
                    TextField("Budget Amount", text: $newBudgetAmount)
                        .keyboardType(.decimalPad)
                    
                    Button("Add") {
                        let categoryName = selectedCategory == "Other" ? customCategoryName : selectedCategory
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedAmount = newBudgetAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let amount = Double(trimmedAmount), amount > 0, !trimmedName.isEmpty {
                            let newCat = BudgetCategory(name: trimmedName, budgetAmount: amount)
                            modelContext.insert(newCat)
                            try? modelContext.save()
                            newBudgetAmount = ""
                            customCategoryName = ""
                            selectedCategory = "Food"
                        }
                    }
                }
                
                Section(header: Text("Edit Budgets")) {
                    ForEach(categories) { category in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(.headline)
                                Text("₹\(category.budgetAmount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button("Edit") {
                                    // Edit functionality can be added here
                                }
                                Button("Delete", role: .destructive) {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Setup Budgets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .alert("Delete Budget Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this budget category? This action cannot be undone.")
            }
        }
    }
    
    private func deleteCategory(_ category: BudgetCategory) {
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
    }
}
