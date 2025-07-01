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
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        var id: String { self.rawValue }
    }

    @Query(sort: \Task.priority, order: .forward) private var tasks: [Task]

    var filteredTasks: [Task] {
        tasks.filter { task in
            (statusFilter == .all || task.status.rawValue == statusFilter.rawValue) &&
            task.dueDate >= startDate && task.dueDate <= endDate
        }
    }

    var body: some View {
        NavigationStack {
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
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task) {
                                selectedTask = task
                                showingEditSheet = true
                            } onDelete: {
                                taskToDelete = task
                                showingDeleteAlert = true
                            } onStatusChange: { status in
                                updateStatus(for: task, to: status)
                            }
                        }
                        .onMove { from, to in
                            moveTasks(from: from, to: to)
                        }
                    }
                    .listStyle(.plain)
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
            .sheet(isPresented: $showingEditSheet) {
                if let task = selectedTask {
                    EditTaskView(task: task)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let task = taskToDelete {
                        deleteTask(task)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
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
    
    private func moveTasks(from source: IndexSet, to destination: Int) {
        let filteredTasksArray = Array(filteredTasks)
        var updatedTasks = filteredTasksArray
        
        // Remove tasks from source indices
        for index in source.sorted(by: >) {
            updatedTasks.remove(at: index)
        }
        
        // Insert tasks at destination
        for (index, task) in source.enumerated() {
            let insertIndex = destination + index
            if insertIndex <= updatedTasks.count {
                updatedTasks.insert(filteredTasksArray[task], at: insertIndex)
            }
        }
        
        // Update priorities based on new order
        for (index, task) in updatedTasks.enumerated() {
            task.priority = index
        }
        
        try? modelContext.save()
    }
} 