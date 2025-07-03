import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var category = "Food"
    @State private var customCategory = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showingCustomCategory = false
    
    let categories = ["Food", "Transport", "Shopping", "Entertainment", "Bills", "Healthcare", "Education", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Expense Name", text: $name)
                    
                    TextField("Amount", text: $amount)
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
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addExpense()
                    }
                }
            }
        }
    }
    
    private func addExpense() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, let finalAmount = Double(amount), finalAmount > 0 else { return }
        
        let finalCategory = showingCustomCategory ? customCategory.trimmingCharacters(in: .whitespacesAndNewlines) : category
        guard !finalCategory.isEmpty else { return }
        
        let newExpense = ExpenseModel(name: trimmedName, amount: finalAmount, category: finalCategory, date: date, notes: trimmedNotes.isEmpty ? nil : trimmedNotes)
        modelContext.insert(newExpense)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save expense: \(error)")
        }
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .modelContainer(for: [ExpenseModel.self], inMemory: true)
} 