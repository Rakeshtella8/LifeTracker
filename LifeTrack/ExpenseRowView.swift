import SwiftUI

struct ExpenseRowView: View {
    var expense: ExpenseModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name).fontWeight(.semibold)
                Text(expense.category).font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.amount, format: .currency(code: "INR")).foregroundColor(.red)
                Text(expense.date, format: .dateTime.day().month().year()).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExpenseRowView(
        expense: ExpenseModel(name: "Lunch", amount: 100, category: "Food")
    )
} 