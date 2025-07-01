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
    @Query(sort: \PaymentReminder.paymentDay) private var reminders: [PaymentReminder]
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
    @State private var showingAddReminder = false
    @State private var calendarMonth: Date = Date()
    @State private var editingReminder: PaymentReminder?
    @State private var showingEditReminder = false
    
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
    
    // Upcoming payments
    private var upcomingReminders: [PaymentReminder] {
        let calendar = Calendar.current
        let now = Date()
        return reminders.filter { reminder in
            let dueDate = nextDueDate(for: reminder)
            // Show if not cleared this month
            if let lastCleared = reminder.lastClearedDate {
                let lastClearedMonth = calendar.component(.month, from: lastCleared)
                let thisMonth = calendar.component(.month, from: now)
                let lastClearedYear = calendar.component(.year, from: lastCleared)
                let thisYear = calendar.component(.year, from: now)
                if lastClearedMonth == thisMonth && lastClearedYear == thisYear {
                    return false
                }
            }
            // Only show if due date is in the future or today
            return dueDate >= now
        }.sorted { nextDueDate(for: $0) < nextDueDate(for: $1) }
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
                    // Calendar with reminder overlays
                    CustomCalendarView(
                        month: $calendarMonth,
                        selectedDay: $selectedDay,
                        reminders: remindersForMonth(calendarMonth),
                        onDaySelected: { day in
                            selectedDay = day
                            showDayExpenses = true
                            startDate = Calendar.current.startOfDay(for: day)
                            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!.addingTimeInterval(-1)
                        }
                    )
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
                    // Upcoming Payments Section
                    if !upcomingReminders.isEmpty {
                        Text("Upcoming Payments").font(.headline)
                        VStack(spacing: 8) {
                            ForEach(upcomingReminders) { reminder in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(reminder.name).fontWeight(.semibold)
                                        Text("Due on \(dueDateString(for: reminder))")
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Button(action: { markAsPaid(reminder) }) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.blue).frame(width: 32, height: 32))
                                    }
                                }
                                .padding(8)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(10)
                            }
                        }
                    }
                    // Reminders Section (all reminders)
                    if !reminders.isEmpty {
                        Text("Reminders").font(.headline)
                        VStack(spacing: 8) {
                            ForEach(reminders) { reminder in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(reminder.name).fontWeight(.semibold)
                                        Text("Due on \(dueDateString(for: reminder))")
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Menu {
                                        Button("Edit") { editingReminder = reminder; showingEditReminder = true }
                                        Button("Delete", role: .destructive) { deleteReminder(reminder) }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
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
    
    private func nextDueDate(for reminder: PaymentReminder) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        return calendar.date(from: DateComponents(year: components.year, month: components.month, day: reminder.paymentDay)) ?? now
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
    
    // Helper to get reminders for the displayed month
    private func remindersForMonth(_ month: Date) -> [PaymentReminder] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        return reminders.filter { r in
            let dueDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: r.paymentDay))
            return dueDate != nil
        }
    }
    
    private func deleteReminder(_ reminder: PaymentReminder) {
        withAnimation {
            modelContext.delete(reminder)
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

// --- Custom Calendar View for Reminders ---
struct CustomCalendarView: View {
    @Binding var month: Date
    @Binding var selectedDay: Date
    var reminders: [PaymentReminder]
    var onDaySelected: (Date) -> Void
    
    private var calendar: Calendar { Calendar.current }
    private var daysInMonth: [Date] {
        let range = calendar.range(of: .day, in: .month, for: month)!
        let components = calendar.dateComponents([.year, .month], from: month)
        return range.compactMap { day -> Date? in
            calendar.date(from: DateComponents(year: components.year, month: components.month, day: day))
        }
    }
    private var reminderDays: Set<Int> {
        let components = calendar.dateComponents([.year, .month], from: month)
        return Set(reminders.filter { r in
            let dueDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: r.paymentDay))
            return dueDate != nil
        }.map { $0.paymentDay })
    }
    var body: some View {
        VStack {
            HStack {
                Button(action: { month = calendar.date(byAdding: .month, value: -1, to: month)! }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(month, format: .dateTime.month().year())
                    .font(.headline)
                Spacer()
                Button(action: { month = calendar.date(byAdding: .month, value: 1, to: month)! }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 4)
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day).frame(maxWidth: .infinity)
                }
            }
            let firstDay = daysInMonth.first!
            let weekday = calendar.component(.weekday, from: firstDay)
            let leadingSpaces = weekday - calendar.firstWeekday
            let totalDays = daysInMonth.count + max(leadingSpaces, 0)
            let rows = Int(ceil(Double(totalDays) / 7.0))
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < max(leadingSpaces, 0) || index - max(leadingSpaces, 0) >= daysInMonth.count {
                            Spacer().frame(maxWidth: .infinity)
                        } else {
                            let dayDate = daysInMonth[index - max(leadingSpaces, 0)]
                            let dayNum = calendar.component(.day, from: dayDate)
                            Button(action: { onDaySelected(dayDate) }) {
                                ZStack {
                                    if calendar.isDate(dayDate, inSameDayAs: selectedDay) {
                                        Circle().fill(Color.blue.opacity(0.2)).frame(width: 36, height: 36)
                                    }
                                    Text("\(dayNum)")
                                        .foregroundColor(.primary)
                                    if reminderDays.contains(dayNum) {
                                        Circle()
                                            .fill(Color.yellow)
                                            .frame(width: 8, height: 8)
                                            .offset(y: 14)
                                    }
                                }
                                .frame(width: 36, height: 36)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
                let components = calendar.dateComponents([.year, .month], from: now)
                paymentDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: reminder.paymentDay)) ?? now
                isRecurring = reminder.isRecurring
            }
        }
    }
    private func saveReminder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let calendar = Calendar.current
        let day = calendar.component(.day, from: paymentDate)
        reminder.name = trimmedName
        reminder.paymentDay = day
        reminder.isRecurring = isRecurring
        try? modelContext.save()
    }
}
