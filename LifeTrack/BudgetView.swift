import SwiftUI
import SwiftData
import Charts

// MARK: - Main Budget View
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = BudgetViewModel()
    
    @State private var showingAddExpense = false
    @State private var showingBudgetSetup = false
    @State private var showingAddReminder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with period picker and summary
                    BudgetHeaderView(
                        selectedPeriod: $viewModel.selectedPeriod,
                        totalSpent: viewModel.totalSpentForPeriod
                    )

                    // Custom Date Range Picker
                    if viewModel.selectedPeriod == .custom {
                        CustomDateRangePicker(
                            startDate: $viewModel.startDate,
                            endDate: $viewModel.endDate
                        )
                    }

                    // Insights Section
                    InsightsView(insights: viewModel.insights)

                    // Pie Chart for expense distribution
                    if !viewModel.pieData.isEmpty {
                        SpendingPieChartView(pieData: viewModel.pieData)
                    }

                    // List of recent transactions
                    RecentTransactionsView(
                        expenses: viewModel.filteredExpenses
                    )

                    // Upcoming payment reminders
                    UpcomingPaymentsView(reminders: viewModel.upcomingReminders)
                }
                .padding()
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingBudgetSetup = true }) {
                            Image(systemName: "gearshape")
                        }
                        Button(action: { showingAddReminder = true }) {
                            Image(systemName: "bell")
                        }
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) { AddExpenseView() }
            .sheet(isPresented: $showingBudgetSetup) { BudgetSetupView() }
            .sheet(isPresented: $showingAddReminder) { AddReminderView() }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .onChange(of: viewModel.selectedPeriod) {
            viewModel.updateDatesForPeriod()
        }
    }
}


// MARK: - Subviews for BudgetView

struct BudgetHeaderView: View {
    @Binding var selectedPeriod: BudgetPeriod
    let totalSpent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(BudgetPeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading) {
                Text("Total Spent (\(selectedPeriod.rawValue))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(totalSpent, format: .currency(code: "INR"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
    }
}

struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct InsightsView: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Insights")
                .font(.headline)
            ForEach(insights, id: \.self) { insight in
                Text("• \(insight)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SpendingPieChartView: View {
    let pieData: [ChartData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Spending by Category")
                .font(.headline)
            Chart(pieData) { data in
                SectorMark(
                    angle: .value("Amount", data.amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 2.0
                )
                .foregroundStyle(by: .value("Category", data.category))
                .cornerRadius(5)
            }
            .frame(height: 250)
        }
    }
}

struct RecentTransactionsView: View {
    let expenses: [ExpenseModel]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Transactions")
                .font(.headline)
            
            if expenses.isEmpty {
                Text("No transactions in this period.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ForEach(expenses) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
    }
}

struct UpcomingPaymentsView: View {
    let reminders: [PaymentReminder]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Upcoming Payments")
                .font(.headline)
            
            if reminders.isEmpty {
                Text("No upcoming payments.")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            } else {
                ForEach(reminders) { reminder in
                    ReminderRowView(reminder: reminder)
                }
            }
        }
    }
}

struct ReminderRowView: View {
    let reminder: PaymentReminder
    
    var body: some View {
        HStack {
            Text(reminder.name)
            Spacer()
            Text(reminder.dates.first ?? Date(), style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    BudgetView()
        .modelContainer(for: [BudgetCategory.self, ExpenseModel.self, PaymentReminder.self], inMemory: true)
}
