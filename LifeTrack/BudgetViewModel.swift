import SwiftUI
import SwiftData
import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var selectedPeriod: BudgetPeriod = .day
    @Published var startDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var endDate: Date = {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
    }()
    
    private var modelContext: ModelContext?
    
    // Published properties for the view
    @Published var categories: [BudgetCategory] = []
    @Published var expenses: [ExpenseModel] = []
    @Published var reminders: [PaymentReminder] = []
    @Published var errorMessage: String?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
    }
    
    private func loadData() {
        guard let modelContext = modelContext else { 
            errorMessage = "Database context is not available"
            return 
        }
        
        do {
            let categoryDescriptor = FetchDescriptor<BudgetCategory>(sortBy: [SortDescriptor(\.name)])
            let expenseDescriptor = FetchDescriptor<ExpenseModel>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let reminderDescriptor = FetchDescriptor<PaymentReminder>(sortBy: [SortDescriptor(\.name)])
            
            categories = try modelContext.fetch(categoryDescriptor)
            expenses = try modelContext.fetch(expenseDescriptor)
            reminders = try modelContext.fetch(reminderDescriptor)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Error loading data: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    var totalSpentForPeriod: Double {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    var insights: [String] {
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
    
    var pieData: [ChartData] {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        return grouped.map { (key, value) in ChartData(category: key, amount: value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.amount > 0 }
    }
    
    var filteredExpenses: [ExpenseModel] {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .prefix(10)
            .map { $0 }
    }
    
    var upcomingReminders: [PaymentReminder] {
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
    
    // MARK: - Helper Methods
    
    private func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func nextDueDate(for reminder: PaymentReminder) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let futureDates = reminder.dates.filter { $0 >= now }
        return futureDates.min() ?? now
    }
    
    func updateDatesForPeriod() {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .day:
            startDate = calendar.startOfDay(for: now)
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: startDate) {
                endDate = nextDay.addingTimeInterval(-1)
            } else {
                endDate = startDate.addingTimeInterval(86399) // 24 hours - 1 second
            }
        case .week:
            if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
                startDate = week.start
                endDate = week.end.addingTimeInterval(-1)
            } else {
                // Fallback to current day if week calculation fails
                startDate = calendar.startOfDay(for: now)
                endDate = startDate.addingTimeInterval(86399)
            }
        case .month:
            if let month = calendar.dateInterval(of: .month, for: now) {
                startDate = month.start
                endDate = month.end.addingTimeInterval(-1)
            } else {
                // Fallback to current day if month calculation fails
                startDate = calendar.startOfDay(for: now)
                endDate = startDate.addingTimeInterval(86399)
            }
        case .custom:
            // Custom dates are already set via bindings
            break
        }
    }
    
    func deleteExpense(_ expense: ExpenseModel) {
        guard let modelContext = modelContext else { 
            errorMessage = "Cannot delete expense: database context unavailable"
            return 
        }
        
        do {
            withAnimation {
                modelContext.delete(expense)
                try modelContext.save()
                loadData()
            }
        } catch {
            errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
    }
    
    func markReminderAsPaid(_ reminder: PaymentReminder) {
        guard let modelContext = modelContext else { 
            errorMessage = "Cannot mark reminder as paid: database context unavailable"
            return 
        }
        
        do {
            reminder.lastClearedDate = Date()
            try modelContext.save()
            loadData()
        } catch {
            errorMessage = "Failed to mark reminder as paid: \(error.localizedDescription)"
        }
    }
}

// MARK: - Budget Setup View
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
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
    }()
    
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
                            let newCat = BudgetCategory(name: trimmedName, budgetAmount: amount, type: budgetType, startDate: startDate, endDate: endDate)
                            modelContext.insert(newCat)
                            do {
                                try modelContext.save()
                                newBudgetAmount = ""
                                customCategoryName = ""
                                selectedCategory = "Food"
                            } catch {
                                print("Failed to save category: \(error)")
                            }
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
        do {
            withAnimation {
                modelContext.delete(category)
                try modelContext.save()
            }
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
}

// MARK: - Edit Reminder View
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
                paymentDate = reminder.dates.first ?? Date()
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
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}
