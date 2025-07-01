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
                Section(header: Text("Description (optional)")) {
                    TextEditor(text: Binding(
                        get: { task.taskDescription ?? "" },
                        set: { task.taskDescription = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
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