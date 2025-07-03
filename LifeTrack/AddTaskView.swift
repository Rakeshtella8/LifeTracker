import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Task.priority, order: .reverse) private var tasks: [Task]
    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var status: Status = .notStarted
    @State private var taskDescription: String = ""

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
                Section(header: Text("Description (optional)")) {
                    TextEditor(text: $taskDescription)
                        .frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let nextPriority = tasks.first?.priority ?? -1
        let newTask = Task(title: trimmedTitle, dueDate: dueDate, status: status, priority: nextPriority + 1, taskDescription: taskDescription.isEmpty ? nil : taskDescription)
        modelContext.insert(newTask)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save task: \(error)")
        }
    }
} 