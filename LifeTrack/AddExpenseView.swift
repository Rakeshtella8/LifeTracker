import SwiftUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var note: String = ""
    @State private var amount: Double?
    @State private var date: Date = Date()
    @State private var category: String = "Food"
    let categories = ["Food", "Transport", "Shopping", "Utilities", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Note (e.g., Lunch)", text: $note)
                    TextField("Amount", value: $amount, format: .currency(code: "INR"))
                        .keyboardType(.decimalPad)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addExpense()
                        dismiss()
                    }
                    .disabled(note.isEmpty || amount == nil)
                }
            }
        }
    }

    private func addExpense() {
        guard let finalAmount = amount, finalAmount > 0 else { return }
        withAnimation {
            let newExpense = Expense(amount: finalAmount, date: date, category: category, paymentMode: "Card", note: note)
            modelContext.insert(newExpense)
            try? modelContext.save()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var note = ""
        @State var amount: Double? = nil
        @State var date = Date()
        @State var category = "Food"
        var body: some View {
            AddExpenseView()
        }
    }
    return PreviewWrapper()
} 