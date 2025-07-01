import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedTask: Task?
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    @State private var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        var id: String { self.rawValue }
    }

    @Query(sort: \Task.dueDate, order: .forward) private var tasks: [Task]

    var filteredTasks: [Task] {
        tasks.filter { task in
            (statusFilter == .all || task.status.rawValue == statusFilter.rawValue) &&
            task.dueDate >= startDate && task.dueDate <= endDate
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    DateFilterView(startDate: $startDate, endDate: $endDate)
                    Picker("Status", selection: $statusFilter) {
                        ForEach(StatusFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if filteredTasks.isEmpty {
                        ContentUnavailableView("No Tasks Yet", systemImage: "checkmark.circle", description: Text("Tap the + button to add your first task."))
                            .padding(.top, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredTasks) { task in
                                NavigationLink {
                                    EditTaskView(task: task)
                                } label: {
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
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .contextMenu {
                                    ForEach(Status.allCases, id: \.self) { status in
                                        Button(status.rawValue) {
                                            updateStatus(for: task, to: status)
                                        }
                                    }
                                    Button("Delete", role: .destructive) {
                                        deleteTask(task)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding([.horizontal, .top])
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTaskView()
            }
        }
    }

    private func color(for status: Status) -> Color {
        switch status {
        case .notStarted: return .gray
        case .inProgress: return .orange
        case .completed: return .green
        }
    }

    private func updateStatus(for task: Task, to status: Status) {
        task.status = status
        try? modelContext.save()
    }

    private func deleteTask(_ task: Task) {
        withAnimation {
            modelContext.delete(task)
            try? modelContext.save()
        }
    }
} 