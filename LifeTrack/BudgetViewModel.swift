import Foundation
import SwiftUI
import SwiftData

class BudgetViewModel: ObservableObject {
    @Published var categories: [BudgetCategory] = []
    @Published var expenses: [Expense] = []
    @Published var insights: [String] = []
    @Published var pieData: [ChartData] = []
    @Published var startDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchCategories()
        fetchExpenses()
        calculateInsights()
        calculatePieData()
    }
    
    func fetchCategories() {
        let descriptor = FetchDescriptor<BudgetCategory>(sortBy: [SortDescriptor(\BudgetCategory.name)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchExpenses() {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\Expense.date, order: .reverse)])
        expenses = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    func calculateInsights() {
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
        insights = tips.isEmpty ? ["You're managing your budget well!"] : tips
    }
    
    func calculatePieData() {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        pieData = grouped.map { (key, value) in ChartData(category: key, amount: value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.amount > 0 }
    }
} 