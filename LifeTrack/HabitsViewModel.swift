import Foundation
import SwiftUI
import SwiftData

class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var completions: [HabitCompletion] = []
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchHabits()
        fetchCompletions()
    }
    
    func fetchHabits() {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\Habit.createdAt, order: .reverse)])
        habits = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchCompletions() {
        let descriptor = FetchDescriptor<HabitCompletion>(sortBy: [SortDescriptor(\HabitCompletion.completionDate, order: .reverse)])
        completions = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addHabit(_ habit: Habit) {
        modelContext.insert(habit)
        fetchHabits()
    }
    
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        fetchHabits()
    }
    
    func toggleCompletion(for habit: Habit) {
        let today = Date().startOfDay
        let isCompletedToday = habit.completions?.contains(where: { $0.completionDate.isSameDay(as: today) }) ?? false
        
        if isCompletedToday {
            // Remove today's completion
            if let completion = habit.completions?.first(where: { $0.completionDate.isSameDay(as: today) }) {
                modelContext.delete(completion)
            }
        } else {
            // Add today's completion
            let newCompletion = HabitCompletion(completionDate: Date())
            newCompletion.habit = habit
            modelContext.insert(newCompletion)
        }
        
        fetchCompletions()
    }
    
    func calculateStreak(for habit: Habit) -> (current: Int, longest: Int) {
        guard let completions = habit.completions, !completions.isEmpty else { return (0, 0) }
        
        let sortedDates = completions.map { $0.completionDate.startOfDay }.sorted().removingDuplicates()
        
        var currentStreak = 0
        var longestStreak = 0
        var streakStartDate = Date().startOfDay
        
        if let lastCompletion = sortedDates.last, 
           lastCompletion.isSameDay(as: Date().startOfDay) || 
           lastCompletion.isSameDay(as: Calendar.current.date(byAdding: .day, value: -1, to: Date())!.startOfDay) {
            // Check for current streak
            for date in sortedDates.reversed() {
                if date.isSameDay(as: streakStartDate) {
                    currentStreak += 1
                    streakStartDate = Calendar.current.date(byAdding: .day, value: -1, to: streakStartDate)!
                } else {
                    break
                }
            }
        }
        
        // Check for longest streak
        var currentLongest = 0
        for i in 0..<sortedDates.count {
            if i > 0 && sortedDates[i] == Calendar.current.date(byAdding: .day, value: 1, to: sortedDates[i-1]) {
                currentLongest += 1
            } else {
                currentLongest = 1
            }
            if currentLongest > longestStreak {
                longestStreak = currentLongest
            }
        }
        
        return (currentStreak, longestStreak)
    }
} 