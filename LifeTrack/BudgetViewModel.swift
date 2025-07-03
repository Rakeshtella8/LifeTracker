import Foundation
import SwiftUI
import SwiftData

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var categories: [BudgetCategory] = []
    @Published var expenses: [ExpenseModel] = []
    @Published var insights: [String] = []
    @Published var pieData: [ChartData] = []
    @Published var startDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    @Published var selectedPeriod: BudgetPeriod = .month
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExpenses()
        fetchCategories()
        calculateInsights()
        calculatePieData()
    }
    
    func fetchExpenses() {
        let descriptor = FetchDescriptor<ExpenseModel>(sortBy: [SortDescriptor(\ExpenseModel.date, order: .reverse)])
        expenses = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchCategories() {
        let descriptor = FetchDescriptor<BudgetCategory>(sortBy: [SortDescriptor(\BudgetCategory.name)])
        let allCategories = (try? modelContext.fetch(descriptor)) ?? []
        categories = allCategories.filter { $0.type.rawValue == self.selectedPeriod.rawValue }
    }
    
    func spent(for category: BudgetCategory) -> Double {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    func calculateInsights() {
        var tips: [String] = []
        for category in categoriesForSelectedPeriod {
            let spentAmount = spent(for: category)
            let percent = category.budgetAmount == 0 ? 0 : Int((spentAmount / category.budgetAmount) * 100)
            if percent >= 80 {
                tips.append("You are \(percent)% of the way to your '\(category.name)' budget for this period.")
            }
        }
        if let highest = categoriesForSelectedPeriod.max(by: { spent(for: $0) < spent(for: $1) }), spent(for: highest) > 0 {
            tips.append("Your highest spending category is '\(highest.name)'.")
        }
        insights = tips.isEmpty ? ["You're managing your budget well!"] : tips
    }
    
    func calculatePieData() {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        pieData = grouped.map { (key, value) in ChartData(category: key, amount: value.reduce(0) { $0 + $1.amount }) }
            .filter { $0.amount > 0 }
    }
    
    var categoriesForSelectedPeriod: [BudgetCategory] {
        categories.filter { $0.type.rawValue == selectedPeriod.rawValue }
    }
    
    func expensesForCategory(_ category: BudgetCategory, startDate: Date, endDate: Date) -> [ExpenseModel] {
        expenses.filter { $0.category == category.name && $0.date >= startDate && $0.date <= endDate }
    }
    
    func totalSpentForPeriod(startDate: Date, endDate: Date) -> Double {
        expenses.filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.amount }
    }
    
    func spendingByCategory(startDate: Date, endDate: Date) -> [String: Double] {
        let grouped = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }, by: { $0.category })
        return grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
} 