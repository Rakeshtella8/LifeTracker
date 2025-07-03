import SwiftUI
import SwiftData

struct TasksViewContainer: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        TasksView(viewModel: TasksViewModel(modelContext: modelContext))
    }
}

struct TasksView: View {
    @StateObject var viewModel: TasksViewModel
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var selectedTask: Task?
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                DateFilterView(startDate: $viewModel.startDate, endDate: $viewModel.endDate)
                Picker("Status", selection: $viewModel.statusFilter) {
                    ForEach(TasksViewModel.StatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                if viewModel.filteredTasks.isEmpty {
                    ContentUnavailableView("No Tasks Yet", systemImage: "checkmark.circle", description: Text("Tap the + button to add your first task."))
                        .padding(.top, 20)
                } else {
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(task: task) {
                                selectedTask = task
                                showingEditSheet = true
                            } onDelete: {
                                taskToDelete = task
                                showingDeleteAlert = true
                            } onStatusChange: { status in
                                viewModel.updateStatus(for: task, to: status)
                            }
                        }
                        .onMove { from, to in
                            viewModel.reorderTasks(from: from, to: to)
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
                        viewModel.deleteTask(task)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
        }
    }
} 
