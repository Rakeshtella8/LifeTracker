import SwiftUI

struct EditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Bindable var task: Task

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Title", text: $task.title)
                DatePicker("Due Date", selection: $task.dueDate, displayedComponents: .date)
                Picker("Status", selection: $task.status) {
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Changes are auto-saved in SwiftData
                        dismiss()
                    }
                }
            }
        }
    }
} 