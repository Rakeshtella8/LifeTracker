import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    func scheduleNotifications(for reminder: PaymentReminder) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule notifications for each date in the reminder
        for dueDate in reminder.dates {
            if dueDate >= now {
                // Schedule notification for the due date and 2 days before
                for offset in (-2)...0 {
                    let notificationDate = calendar.date(byAdding: .day, value: offset, to: dueDate) ?? dueDate
                    if notificationDate >= now {
                        let content = UNMutableNotificationContent()
                        content.title = "Payment Reminder"
                        content.body = "\(reminder.name) is due on \(dateFormatter.string(from: dueDate))."
                        content.sound = .default
                        let triggerDate = calendar.dateComponents([.year, .month, .day], from: notificationDate)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                        let request = UNNotificationRequest(identifier: notificationID(for: reminder, date: notificationDate), content: content, trigger: trigger)
                        center.add(request)
                    }
                }
            }
        }
    }
    
    func cancelNotifications(for reminder: PaymentReminder) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        var ids: [String] = []
        
        // Cancel notifications for each date in the reminder
        for dueDate in reminder.dates {
            for offset in (-2)...0 {
                let notificationDate = calendar.date(byAdding: .day, value: offset, to: dueDate) ?? dueDate
                ids.append(notificationID(for: reminder, date: notificationDate))
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    private func notificationID(for reminder: PaymentReminder, date: Date) -> String {
        return "reminder_\(reminder.id.uuidString)_\(date.timeIntervalSince1970)"
    }
} 