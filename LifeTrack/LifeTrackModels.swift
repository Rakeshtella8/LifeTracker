import Foundation
import SwiftData

// MARK: - Task Status Enum
enum Status: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
}

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var frequencyType: String // "daily", "weekly"
    var reminderTime: Date?
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]? = []

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), frequencyType: String = "daily", reminderTime: Date? = nil, isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.frequencyType = frequencyType
        self.reminderTime = reminderTime
        self.isArchived = isArchived
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
    var tags: [String]?
    var taskDescription: String?

    init(id: UUID = UUID(), title: String, dueDate: Date = Date(), status: Status = .notStarted, tags: [String]? = nil, taskDescription: String? = nil) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.status = status
        self.tags = tags
        self.taskDescription = taskDescription
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var category: String
    var paymentMode: String
    var note: String

    init(id: UUID = UUID(), amount: Double, date: Date = Date(), category: String, paymentMode: String, note: String) {
        self.id = id
        self.amount = amount
        self.date = date
        self.category = category
        self.paymentMode = paymentMode
        self.note = note
    }
}

// MARK: - Budget Category Model
@Model
final class BudgetCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var budgetAmount: Double

    init(id: UUID = UUID(), name: String, budgetAmount: Double) {
        self.id = id
        self.name = name
        self.budgetAmount = budgetAmount
    }
} 