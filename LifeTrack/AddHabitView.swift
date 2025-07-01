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
        let newHabit = Habit(name: name)
        modelContext.insert(newHabit)
    }
}

#Preview {
    AddHabitView()
} 