import Foundation

extension Habit {
    /// Calculates the current and longest streaks for a habit.
    var streak: (current: Int, longest: Int) {
        guard let completions = self.completions, !completions.isEmpty else {
            return (0, 0)
        }

        let sortedDates = completions
            .map { $0.completionDate.startOfDay }
            .removingDuplicates()
            .sorted()

        guard !sortedDates.isEmpty else {
            return (0, 0)
        }

        // Calculate Longest Streak
        var longestStreak = 0
        if !sortedDates.isEmpty {
            var currentLongest = 1
            for i in 1..<sortedDates.count {
                if let expectedPreviousDay = Calendar.current.date(byAdding: .day, value: -1, to: sortedDates[i]),
                   sortedDates[i-1].isSameDay(as: expectedPreviousDay) {
                    currentLongest += 1
                } else {
                    currentLongest = 1
                }
                if currentLongest > longestStreak {
                    longestStreak = currentLongest
                }
            }
            if longestStreak == 0 { // If loop didn't run
                longestStreak = 1
            }
        }

        // Calculate Current Streak
        var currentStreak = 0
        let today = Calendar.current.startOfDay(for: Date())
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
            return (currentStreak, longestStreak)
        }

        if sortedDates.contains(where: { $0.isSameDay(as: today) }) || sortedDates.contains(where: { $0.isSameDay(as: yesterday) }) {
            var dateToFind = today
            if !sortedDates.contains(where: { $0.isSameDay(as: dateToFind) }) {
                dateToFind = yesterday
            }
            
            for date in sortedDates.reversed() {
                if date.isSameDay(as: dateToFind) {
                    currentStreak += 1
                    if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: dateToFind) {
                        dateToFind = previousDay
                    } else {
                        break
                    }
                } else if date < dateToFind {
                    // This means a day was missed
                    break
                }
            }
        }
        
        return (currentStreak, longestStreak)
    }
}

// Helper to remove duplicate dates
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
} 