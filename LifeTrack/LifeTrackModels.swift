import Foundation
import SwiftData

enum BudgetPeriod: String, CaseIterable, Identifiable, Codable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case custom = "Custom"
    var id: String { self.rawValue }
}

// MARK: - Task Status Enum
enum Status: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
}

enum BudgetType: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    var id: String { self.rawValue }
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var frequencyType: String // "daily", "weekly"
    var reminderTime: Date?
    var isArchived: Bool
    var isActive: Bool
    var frequency: String // "daily", "weekly", "monthly"
    var lastCompleted: Date?

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]? = []

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), frequencyType: String = "daily", reminderTime: Date? = nil, isArchived: Bool = false, isActive: Bool = true, frequency: String = "daily", lastCompleted: Date? = nil) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.frequencyType = frequencyType
        self.reminderTime = reminderTime
        self.isArchived = isArchived
        self.isActive = isActive
        self.frequency = frequency
        self.lastCompleted = lastCompleted
    }
}

@Model
final class HabitCompletion {
    @Attribute(.unique) var id: UUID
    var completionDate: Date

    var habit: Habit?

    init(id: UUID = UUID(), completionDate: Date = Date()) {
        self.id = id
        self.completionDate = completionDate
    }
}

@Model
final class Task {
    @Attribute(.unique) var id: UUID
    var title: String
    var dueDate: Date
    var status: Status // Now uses the Status enum
    var priority: Int // For manual ordering
    var tags: [String]?
    var taskDescription: String?

    init(id: UUID = UUID(), title: String, dueDate: Date = Date(), status: Status = .notStarted, priority: Int = 0, tags: [String]? = nil, taskDescription: String? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.tags = tags
        self.taskDescription = taskDescription
    }
}

@Model
final class ExpenseModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var category: String
    var date: Date
    var notes: String?
    
    init(name: String, amount: Double, category: String, date: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
    }
}

// MARK: - Budget Category Model
@Model
final class BudgetCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var budgetAmount: Double
    var type: BudgetType
    var startDate: Date?
    var endDate: Date?

    init(name: String, budgetAmount: Double, type: BudgetType = .monthly, startDate: Date? = nil, endDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.budgetAmount = budgetAmount
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
    }
}

@Model
final class PaymentReminder {
    @Attribute(.unique) var id: UUID
    var name: String
    var dates: [Date] // support multiple dates
    var amount: Double?
    var isRecurring: Bool
    var lastClearedDate: Date?

    init(name: String, dates: [Date], amount: Double? = nil, isRecurring: Bool = false, lastClearedDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.dates = dates
        self.amount = amount
        self.isRecurring = isRecurring
        self.lastClearedDate = lastClearedDate
    }
} 