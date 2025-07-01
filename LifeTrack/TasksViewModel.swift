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
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\Task.dueDate, order: .forward)])
        tasks = (try? modelContext.fetch(descriptor)) ?? []
        applyFilters()
    }
    
    func applyFilters() {
        filteredTasks = tasks.filter { task in
            (statusFilter == .all || task.status.rawValue == statusFilter.rawValue) &&
            task.dueDate >= startDate && task.dueDate <= endDate
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
} 