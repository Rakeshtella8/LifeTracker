import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var paymentDate: Date = Date()
    @State private var isRecurring: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder Details") {
                    TextField("Reminder Name", text: $name)
                    DatePicker("Payment Day", selection: $paymentDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    Toggle("Remind me every month", isOn: $isRecurring)
                }
            }
            .navigationTitle("Add Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addReminder()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addReminder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let reminder = PaymentReminder(name: trimmedName, dates: [paymentDate], isRecurring: isRecurring)
        modelContext.insert(reminder)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save reminder: \(error)")
        }
        // NotificationManager.shared.scheduleNotifications(for: reminder) // To be implemented
    }
}

#Preview {
    AddReminderView()
} 