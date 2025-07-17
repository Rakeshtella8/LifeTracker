import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.priority) private var tasks: [Task]
    
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedTask: Task?
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?

    // Filters
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
    @State private var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        var id: String { self.rawValue }
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

                FilteredTasksView(
                    startDate: startDate,
                    endDate: endDate,
                    statusFilter: statusFilter,
                    onEdit: { task in
                        selectedTask = task
                        showingEditSheet = true
                    },
                    onDelete: { task in
                        taskToDelete = task
                        showingDeleteAlert = true
                    },
                    onStatusChange: { task, newStatus in
                        updateStatus(for: task, to: newStatus)
                    },
                    onMove: { source, destination in
                        reorderTasks(from: source, to: destination, for: tasks)
                    }
                )
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
            .sheet(isPresented: $showingAddSheet) { AddTaskView() }
            .sheet(isPresented: $showingEditSheet) {
                if let task = selectedTask {
                    EditTaskView(task: task)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let task = taskToDelete {
                        deleteTask(task)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this task?")
            }
        }
    }

    private func deleteTask(_ task: Task) {
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    private func updateStatus(for task: Task, to newStatus: Status) {
        task.status = newStatus
        try? modelContext.save()
    }
    
    private func reorderTasks(from source: IndexSet, to destination: Int, for tasks: [Task]) {
        var items = tasks
        items.move(fromOffsets: source, toOffset: destination)
        for (index, task) in items.enumerated() {
            task.priority = index
        }
        try? modelContext.save()
    }
}

struct FilteredTasksView: View {
    @Query private var tasks: [Task]

    let onEdit: (Task) -> Void
    let onDelete: (Task) -> Void
    let onStatusChange: (Task, Status) -> Void
    let onMove: (IndexSet, Int) -> Void

    init(startDate: Date, endDate: Date, statusFilter: TasksView.StatusFilter, onEdit: @escaping (Task) -> Void, onDelete: @escaping (Task) -> Void, onStatusChange: @escaping (Task, Status) -> Void, onMove: @escaping (IndexSet, Int) -> Void) {
        let statusRawValue = statusFilter.rawValue
        let predicate = #Predicate<Task> { task in
            let isInRange = task.dueDate >= startDate && task.dueDate < endDate
            if statusFilter == .all {
                return isInRange
            } else {
                return isInRange && task.status.rawValue == statusRawValue
            }
        }
        _tasks = Query(filter: predicate, sort: \.priority)
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onStatusChange = onStatusChange
        self.onMove = onMove
    }

    var body: some View {
        if tasks.isEmpty {
            ContentUnavailableView("No Tasks", systemImage: "checkmark.circle", description: Text("No tasks match the current filters."))
                .padding(.top, 20)
        } else {
            List {
                ForEach(tasks) { task in
                    TaskRowView(task: task, onEdit: {
                        onEdit(task)
                    }, onDelete: {
                        onDelete(task)
                    }, onStatusChange: { newStatus in
                        onStatusChange(task, newStatus)
                    })
                }
                .onMove(perform: onMove)
            }
            .listStyle(.plain)
        }
    }
}
