import SwiftUI
import SwiftData
import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \ExpenseModel.date, order: .reverse) private var expenses: [ExpenseModel]
    @Query(sort: \PaymentReminder.name) private var reminders: [PaymentReminder]
    @State private var showingAddSheet = false
    @State private var showingBudgetSetup = false
    @State private var showingEditSheet = false
    @State private var selectedExpense: ExpenseModel?
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    @State private var selectedPeriod: BudgetPeriod = .day
    @State private var selectedDay: Date = Date()
    @State private var showDayExpenses: Bool = false
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: ExpenseModel?
    @State private var showingAddReminder = false
    @State private var calendarMonth: Date = Date()
    @State private var editingReminder: PaymentReminder?
    @State private var showingEditReminder = false
    @State private var isCustomRange: Bool = false
    
    var body: some View {
        NavigationStack {
            content
        }
    }
    
    private var content: some View {
        ScrollView {
            mainVStack
        }
        .navigationTitle("Budget")
        .sheet(isPresented: $showingBudgetSetup) {
            BudgetSetupView()
        }
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExpenseView()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let expense = selectedExpense {
                EditExpenseView(expense: expense)
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView()
        }
        .sheet(isPresented: $showingEditReminder) {
            if let reminder = editingReminder {
                EditReminderView(reminder: reminder)
            }
        }
        .alert("Delete Expense", isPresented: $showingDeleteAlert) {
            deleteAlertButtons
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }
    
    private var mainVStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            periodPickerView
        }
        .padding()
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
                Button(action: { showingAddReminder = true }) {
                    Image(systemName: "bell.fill")
                }
            }
        }
    }
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            if let expense = expenseToDelete {
                deleteExpense(expense)
            }
        }
    }
    
    private var periodPickerView: some View {
        VStack(spacing: 8) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(BudgetPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
                Text("Custom").tag(BudgetPeriod?.none)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPeriod) {
                isCustomRange = false
                updateDatesForPeriod()
            }
            
            Button("Custom Range") {
                isCustomRange = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Computed Properties
    
    private func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
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
    
    private var pieData: [ChartData] {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        return grouped.map { (key, value) in ChartData(category: key, amount: value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.amount > 0 }
    }
    
    private var recentTransactions: [ExpenseModel] {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .prefix(10)
            .map { $0 }
    }
    
    private var dayExpenses: [ExpenseModel] {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }
    
    private var upcomingPayments: [PaymentReminder] {
        let calendar = Calendar.current
        let now = Date()
        return reminders.filter { reminder in
            let dueDate = nextDueDate(for: reminder)
            if let lastCleared = reminder.lastClearedDate {
                let lastClearedMonth = calendar.component(.month, from: lastCleared)
                let thisMonth = calendar.component(.month, from: now)
                let lastClearedYear = calendar.component(.year, from: lastCleared)
                let thisYear = calendar.component(.year, from: now)
                if lastClearedMonth == thisMonth && lastClearedYear == thisYear {
                    return false
                }
            }
            return dueDate >= now
        }.sorted { nextDueDate(for: $0) < nextDueDate(for: $1) }
    }
    
    private var todayExpenses: [ExpenseModel] {
        expenses.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
    }
    
    // MARK: - Helper Methods
    
    private func updateDatesForPeriod() {
        let calendar = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .day:
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
        }
    }
    
    private func deleteExpense(_ expense: ExpenseModel) {
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
        }
    }
    
    private func nextDueDate(for reminder: PaymentReminder) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let futureDates = reminder.dates.filter { $0 >= now }
        return futureDates.min() ?? now
    }
    
    private func dueDateString(for reminder: PaymentReminder) -> String {
        let date = nextDueDate(for: reminder)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func markAsPaid(_ reminder: PaymentReminder) {
        reminder.lastClearedDate = Date()
        try? modelContext.save()
        NotificationManager.shared.cancelNotifications(for: reminder)
    }
    
    private func remindersForMonth(_ month: Date) -> [PaymentReminder] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        return reminders.filter { r in
            return r.dates.contains { date in
                let dateComponents = calendar.dateComponents([.year, .month], from: date)
                return dateComponents.year == components.year && dateComponents.month == components.month
            }
        }
    }
    
    private func deleteReminder(_ reminder: PaymentReminder) {
        withAnimation {
            modelContext.delete(reminder)
            try? modelContext.save()
        }
    }
    
    private func nextDueDateString(for reminder: PaymentReminder) -> String {
        let date = nextDueDate(for: reminder)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Properties
    private var topSpendingCategory: String? {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.max(by: { $0.value < $1.value })?.key
    }
    private var highestSpendingDay: Date? {
        let grouped = Dictionary(grouping: expenses, by: { Calendar.current.startOfDay(for: $0.date) })
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.max(by: { $0.value < $1.value })?.key
    }
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
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
    @State private var budgetType: BudgetType = .daily
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    
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
                    
                    Picker("Budget Type", selection: $budgetType) {
                        ForEach(BudgetType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Button("Add") {
                        let categoryName = selectedCategory == "Other" ? customCategoryName : selectedCategory
                        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedAmount = newBudgetAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let amount = Double(trimmedAmount), amount > 0, !trimmedName.isEmpty {
                            let newCat = BudgetCategory(name: trimmedName, budgetAmount: amount, budgetType: budgetType, startDate: startDate, endDate: endDate)
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

// --- Custom Calendar View for Reminders ---
struct CustomCalendarView: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    var reminders: [PaymentReminder]
    var onDaySelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { month = calendar.date(byAdding: .month, value: -1, to: month)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(month, format: .dateTime.year().month())
                    .font(.headline)
                Spacer()
                Button(action: { month = calendar.date(byAdding: .month, value: 1, to: month)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 4)
            
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(generateGrid(), id: \.self) { date in
                    if let date = date {
                        Button(action: { onDaySelected(date) }) {
                            ZStack {
                                if calendar.isDate(date, inSameDayAs: selectedDay) {
                                    Circle().fill(Color.blue.opacity(0.2)).frame(width: 36, height: 36)
                                }
                                Text("\(calendar.component(.day, from: date))")
                                    .foregroundColor(.primary)
                                if hasReminder(on: date) {
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 8, height: 8)
                                        .offset(y: 14)
                                }
                            }
                            .frame(width: 36, height: 36)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func generateGrid() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var grid: [Date?] = Array(repeating: nil, count: leadingSpaces)
        
        let days = calendar.range(of: .day, in: .month, for: month)!.compactMap {
            calendar.date(bySetting: .day, value: $0, of: month)
        }
        
        grid.append(contentsOf: days)
        
        return grid
    }
    
    private func hasReminder(on date: Date) -> Bool {
        reminders.contains { reminder in
            reminder.dates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
        }
    }
}

// --- Edit Reminder View ---
struct EditReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var reminder: PaymentReminder
    @State private var name: String = ""
    @State private var paymentDate: Date = Date()
    @State private var isRecurring: Bool = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Details") {
                    TextField("Reminder Name", text: $name)
                    DatePicker("Payment Day", selection: $paymentDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    Toggle("Remind me every month", isOn: $isRecurring)
                }
            }
            .navigationTitle("Edit Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReminder()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = reminder.name
                let calendar = Calendar.current
                let now = Date()
                // Use the first date from the dates array, or current date if empty
                paymentDate = reminder.dates.first ?? now
                isRecurring = reminder.isRecurring
            }
        }
    }
    private func saveReminder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        reminder.name = trimmedName
        reminder.dates = [paymentDate]
        reminder.isRecurring = isRecurring
        try? modelContext.save()
    }
}
