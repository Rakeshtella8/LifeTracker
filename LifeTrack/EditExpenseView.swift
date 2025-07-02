import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var expense: ExpenseModel
    
    @State private var name: String = ""
    @State private var amount: Double = 0
    @State private var category: String = "Food"
    @State private var customCategory: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var showingCustomCategory = false
    
    let categories = ["Food", "Transport", "Shopping", "Entertainment", "Bills", "Healthcare", "Education", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Expense Name", text: $name)
                    
                    TextField("Amount", value: $amount, format: .currency(code: "INR"))
                        .keyboardType(.decimalPad)
                    
                    if showingCustomCategory {
                        TextField("Custom Category", text: $customCategory)
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    }
                    
                    Button(showingCustomCategory ? "Use Preset Categories" : "Add Custom Category") {
                        showingCustomCategory.toggle()
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                }
            }
            .onAppear {
                name = expense.name
                amount = expense.amount
                date = expense.date
                notes = expense.notes ?? ""
                
                if categories.contains(expense.category) {
                    category = expense.category
                } else {
                    customCategory = expense.category
                    showingCustomCategory = true
                }
            }
        }
    }
    
    private func saveExpense() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, amount > 0 else { return }
        
        let finalCategory = showingCustomCategory ? customCategory.trimmingCharacters(in: .whitespacesAndNewlines) : category
        guard !finalCategory.isEmpty else { return }
        
        expense.name = trimmedName
        expense.amount = amount
        expense.date = date
        expense.category = finalCategory
        expense.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    EditExpenseView(expense: ExpenseModel(name: "Lunch", amount: 100, category: "Food"))
        .modelContainer(for: [ExpenseModel.self], inMemory: true)
} 