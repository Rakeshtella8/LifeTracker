import Foundation

// Extension for Date helpers
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    func isSameDay(as otherDate: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
}

// Extension for removing duplicates from an array
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
} 