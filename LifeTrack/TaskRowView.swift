import SwiftUI

struct TaskRowView: View, Equatable {
    static func == (lhs: TaskRowView, rhs: TaskRowView) -> Bool {
        lhs.task.id == rhs.task.id && lhs.task.status == rhs.task.status && lhs.task.title == rhs.task.title && lhs.task.dueDate == rhs.task.dueDate
    }
    var task: Task
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onStatusChange: (Status) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(task.title)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(task.status.rawValue)
                        .font(.caption)
                        .foregroundColor(color(for: task.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color(for: task.status).opacity(0.15))
                        .cornerRadius(6)
                }
                Text("Due: \(task.dueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                ForEach(Status.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        onStatusChange(status)
                    }
                }
            } label: {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(color(for: task.status))
            }
            
            OptionsMenuView(onEdit: onEdit, onDelete: onDelete)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func color(for status: Status) -> Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .orange
        case .completed: return .green
        }
    }
}

#Preview {
    TaskRowView(
        task: Task(title: "Sample Task", dueDate: Date()),
        onEdit: { print("Edit") },
        onDelete: { print("Delete") },
        onStatusChange: { status in print("Status: \(status)") }
    )
} 