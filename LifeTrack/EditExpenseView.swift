import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var expense: Expense
    @Query(sort: \BudgetCategory.name) private var budgetCategories: [BudgetCategory]
    
    @State private var note: String = ""
    @State private var amount: Double = 0
    @State private var date: Date = Date()
    @State private var category: String = "Food"
    @State private var customCategory: String = ""
    @State private var showingCustomCategoryField = false
    
    // Default categories plus custom ones from budget setup
    private var allCategories: [String] {
        let defaultCategories = ["Food", "Transport", "Shopping", "Utilities", "Miscellaneous"]
        let customCategories = budgetCategories.map { $0.name }
        return defaultCategories + customCategories + ["Other"]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Note", text: $note)
                    TextField("Amount", value: $amount, format: .currency(code: "INR"))
                        .keyboardType(.decimalPad)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(allCategories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .onChange(of: category) {
                        showingCustomCategoryField = category == "Other"
                    }
                    
                    if showingCustomCategoryField {
                        TextField("Custom Category Name", text: $customCategory)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0 || (category == "Other" && customCategory.isEmpty))
                }
            }
            .onAppear {
                note = expense.note
                amount = expense.amount
                date = expense.date
                
                // Set the category properly
                if allCategories.contains(expense.category) {
                    category = expense.category
                } else {
                    // If it's a custom category not in the list, set to "Other" and populate custom field
                    category = "Other"
                    customCategory = expense.category
                    showingCustomCategoryField = true
                }
            }
        }
    }
    
    private func saveExpense() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty, amount > 0 else { return }
        
        let finalCategory = category == "Other" ? customCategory : category
        
        expense.note = trimmedNote
        expense.amount = amount
        expense.date = date
        expense.category = finalCategory
        try? modelContext.save()
    }
}

#Preview {
    EditExpenseView(expense: Expense(amount: 100, category: "Food", paymentMode: "Card", note: "Lunch"))
} 