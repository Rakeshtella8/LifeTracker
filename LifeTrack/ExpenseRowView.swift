import SwiftUI

struct ExpenseRowView: View {
    var expense: Expense
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.note).fontWeight(.semibold)
                Text(expense.category).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(expense.amount, format: .currency(code: "INR")).foregroundColor(.red)
            OptionsMenuView(onEdit: onEdit, onDelete: onDelete)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    ExpenseRowView(
        expense: Expense(amount: 100, category: "Food", paymentMode: "Card", note: "Lunch"),
        onEdit: { print("Edit") },
        onDelete: { print("Delete") }
    )
} 