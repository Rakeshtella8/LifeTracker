import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var habit: Habit
    
    @State private var name: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit Name", text: $name)
            }
            .navigationTitle("Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = habit.name
            }
        }
    }
    
    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        habit.name = trimmedName
        do {
            try modelContext.save()
        } catch {
            print("Failed to save habit: \(error)")
        }
    }
}

#Preview {
    EditHabitView(habit: Habit(name: "Sample Habit"))
} 