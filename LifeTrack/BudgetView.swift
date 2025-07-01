import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetCategory.name) private var categories: [BudgetCategory]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingAddSheet = false
    @State private var showingBudgetSetup = false

    // Helper: Calculate amount spent in a category this month
    private func spentThisMonth(for category: BudgetCategory) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let monthInterval = calendar.dateInterval(of: .month, for: now)!
        return expenses.filter { $0.category == category.name && monthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    // Helper: Financial Insights
    private var insights: [String] {
        var tips: [String] = []
        for category in categories {
            let spent = spentThisMonth(for: category)
            let percent = category.budgetAmount == 0 ? 0 : Int((spent / category.budgetAmount) * 100)
            if percent >= 80 {
                tips.append("You are \(percent)% of the way to your '\(category.name)' budget for this month.")
            }
        }
        if let highest = categories.max(by: { spentThisMonth(for: $0) < spentThisMonth(for: $1) }), spentThisMonth(for: highest) > 0 {
            tips.append("Your highest spending category is '\(highest.name)'.")
        }
        return tips.isEmpty ? ["You're managing your budget well!"] : tips
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
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
                    List {
                        ForEach(categories) { category in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(category.name).fontWeight(.semibold)
                                    Spacer()
                                    Text("₹\(spentThisMonth(for: category), specifier: "%.2f") / ₹\(category.budgetAmount, specifier: "%.2f")")
                                        .font(.caption)
                                }
                                ProgressView(value: min(spentThisMonth(for: category) / max(category.budgetAmount, 1), 1.0))
                                    .accentColor(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                Divider()
                Text("Financial Insights").font(.headline)
                ForEach(insights, id: \.self) { tip in
                    Text(tip).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddSheet) { AddExpenseView() }
            .sheet(isPresented: $showingBudgetSetup) { BudgetSetupView() }
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
                        if let amount = Double(newBudgetAmount), !newCategoryName.isEmpty {
                            let newCat = BudgetCategory(name: newCategoryName, budgetAmount: amount)
                            modelContext.insert(newCat)
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