import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Habit Name (e.g., Read for 15 mins)", text: $name)
            }
            .navigationTitle("New Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addHabit()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let newHabit = Habit(name: trimmedName, frequency: "daily")
        modelContext.insert(newHabit)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save habit: \(error)")
        }
    }
}

#Preview {
    AddHabitView()
} 