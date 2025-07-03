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
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? startOfDay
    }()
    @State private var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        var id: String { self.rawValue }
    }
    
    var filteredTasks: [Task] {
        tasks.filter { task in
            let isInRange = task.dueDate >= startDate && task.dueDate < endDate
            if statusFilter == .all {
                return isInRange
            } else {
                // This assumes your Status enum and StatusFilter enum have matching rawValues
                return isInRange && task.status.rawValue == statusFilter.rawValue
            }
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
                    ContentUnavailableView("No Tasks", systemImage: "checkmark.circle", description: Text("No tasks match the current filters."))
                        .padding(.top, 20)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task, onEdit: {
                                selectedTask = task
                                showingEditSheet = true
                            }, onDelete: {
                                taskToDelete = task
                                showingDeleteAlert = true
                            }, onStatusChange: { newStatus in
                                updateStatus(for: task, to: newStatus)
                            })
                        }
                        .onMove(perform: reorderTasks)
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

    func deleteTask(_ task: Task) {
        withAnimation {
            modelContext.delete(task)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete task: \(error)")
            }
        }
    }
    
    func toggleTaskStatus(_ task: Task) {
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task status: \(error)")
        }
    }
    
    private func addTask() {
        let newTask = Task(title: "New Task", dueDate: Date())
        modelContext.insert(newTask)
        do {
            try modelContext.save()
        } catch {
            print("Failed to create task: \(error)")
        }
    }
    
    private func updateStatus(for task: Task, to newStatus: Status) {
        task.status = newStatus
        do {
            try modelContext.save()
        } catch {
            print("Failed to update task status: \(error)")
        }
    }
    
    private func reorderTasks(from source: IndexSet, to destination: Int) {
        var items = filteredTasks
        items.move(fromOffsets: source, toOffset: destination)
        for (index, task) in items.enumerated() {
            task.priority = index
        }
        try? modelContext.save()
    }
} 
