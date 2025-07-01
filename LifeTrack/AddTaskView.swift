import SwiftUI

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var status: Status = .notStarted

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Title", text: $title)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let newTask = Task(title: title, dueDate: dueDate, status: status)
        modelContext.insert(newTask)
    }
} 