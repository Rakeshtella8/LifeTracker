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
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingAddSheet = false
    @State private var showingBudgetSetup = false
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)

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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DateFilterView(startDate: $startDate, endDate: $endDate)
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
                    Text("Recent Transactions").font(.headline)
                    if recentTransactions.isEmpty {
                        Text("No transactions in this period.")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentTransactions) { expense in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(expense.note).fontWeight(.semibold)
                                        Text(expense.category).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(expense.amount, format: .currency(code: "INR")).foregroundColor(.red)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
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
        }
    }
}

struct BudgetSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @State private var newCategoryName: String = ""
    @State private var newBudgetAmount: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Category")) {
                    TextField("Category Name", text: $newCategoryName)
                    TextField("Budget Amount", text: $newBudgetAmount)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedAmount = newBudgetAmount.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let amount = Double(trimmedAmount), amount > 0, !trimmedName.isEmpty {
                            let newCat = BudgetCategory(name: trimmedName, budgetAmount: amount)
                            modelContext.insert(newCat)
                            try? modelContext.save()
                            newCategoryName = ""
                            newBudgetAmount = ""
                        }
                    }
                }
                Section(header: Text("Edit Budgets")) {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            TextField("Amount", value: Binding(
                                get: { category.budgetAmount },
                                set: { category.budgetAmount = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                        }
                    }
                }
            }
            .navigationTitle("Setup Budgets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
} 