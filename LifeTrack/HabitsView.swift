import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    
    @State private var showingAddHabit = false
    @State private var habitToEdit: Habit?
    @State private var selectedHabit: Habit?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if habits.isEmpty {
                    ContentUnavailableView("No Habits Yet", systemImage: "figure.mind.and.body", description: Text("Tap the '+' button to add your first habit."))
                } else {
                    List {
                        ForEach(habits) { habit in
                            HabitRowView(habit: habit)
                                .contentShape(Rectangle()) // Make the whole row tappable
                                .onTapGesture {
                                    selectedHabit = habit
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        habitToEdit = habit
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteHabit(habit)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $habitToEdit) { habit in
                EditHabitView(habit: habit)
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit)
            }
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            modelContext.delete(habit)
        }
    }
}

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 15) {
            HabitPlantView(streak: habit.streak.current)

            VStack(alignment: .leading) {
                Text(habit.name)
                    .font(.headline)
                Text(habit.frequency)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: toggleCompletion) {
                Image(systemName: isCompletedToday() ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompletedToday() ? .green : .gray)
                    .font(.title)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
    
    private func isCompletedToday() -> Bool {
        habit.completions?.contains(where: { $0.completionDate.isSameDay(as: Date()) }) ?? false
    }
    
    private func toggleCompletion() {
        let today = Date().startOfDay
        if let completion = habit.completions?.first(where: { $0.completionDate.isSameDay(as: today) }) {
            modelContext.delete(completion)
        } else {
            let newCompletion = HabitCompletion(completionDate: today)
            newCompletion.habit = habit
            modelContext.insert(newCompletion)
        }
    }
}

#Preview {
    HabitsView()
        .modelContainer(for: Habit.self, inMemory: true)
}
