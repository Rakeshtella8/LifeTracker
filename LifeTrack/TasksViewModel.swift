import Foundation
import SwiftUI
import SwiftData

class TasksViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var startDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!.addingTimeInterval(-1)
    @Published var statusFilter: StatusFilter = .all
    
    private var modelContext: ModelContext
    
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        var id: String { self.rawValue }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTasks()
        applyFilters()
    }
    
    func fetchTasks() {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\Task.priority, order: .forward)])
        tasks = (try? modelContext.fetch(descriptor)) ?? []
        applyFilters()
    }
    
    func applyFilters() {
        filteredTasks = tasks.filter { task in
            switch statusFilter {
            case .all:
                return task.dueDate >= startDate && task.dueDate <= endDate
            case .notStarted:
                return task.status == .notStarted && task.dueDate >= startDate && task.dueDate <= endDate
            case .inProgress:
                return task.status == .inProgress && task.dueDate >= startDate && task.dueDate <= endDate
            case .completed:
                return task.status == .completed && task.dueDate >= startDate && task.dueDate <= endDate
            }
        }
    }
    
    func setStatusFilter(_ filter: StatusFilter) {
        statusFilter = filter
        applyFilters()
    }
    
    func setDateRange(start: Date, end: Date) {
        startDate = start
        endDate = end
        applyFilters()
    }
    
    func addTask(_ task: Task) {
        modelContext.insert(task)
        withAnimation {
            filteredTasks.insert(task, at: 0)
        }
        fetchTasks()
    }
    
    func editTask(_ task: Task) {
        // SwiftData auto-saves changes
        fetchTasks()
    }
    
    func deleteTask(_ task: Task) {
        modelContext.delete(task)
        fetchTasks()
    }
    
    func reorderTasks(from source: IndexSet, to destination: Int) {
        var updatedTasks = filteredTasks
        updatedTasks.move(fromOffsets: source, toOffset: destination)
        for (index, task) in updatedTasks.enumerated() {
            task.priority = index
        }
        try? modelContext.save()
        fetchTasks()
    }
    
    func updateStatus(for task: Task, to status: Status) {
        task.status = status
        try? modelContext.save()
        fetchTasks()
    }
} 