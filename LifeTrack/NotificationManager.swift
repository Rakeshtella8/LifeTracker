import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func scheduleNotifications(for reminder: PaymentReminder) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        guard let month = calendar.dateComponents([.year, .month], from: now).month,
              let year = calendar.dateComponents([.year], from: now).year else { return }
        
        // Schedule notifications for 2 days before and on paymentDay
        for offset in (-2)...0 {
            if let dueDate = calendar.date(from: DateComponents(year: year, month: month, day: reminder.paymentDay + offset)) {
                if dueDate >= now {
                    let content = UNMutableNotificationContent()
                    content.title = "Payment Reminder"
                    content.body = "\(reminder.name) is due on the \(reminder.paymentDay)th."
                    content.sound = .default
                    let triggerDate = calendar.dateComponents([.year, .month, .day], from: dueDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                    let request = UNNotificationRequest(identifier: notificationID(for: reminder, date: dueDate), content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }
    
    func cancelNotifications(for reminder: PaymentReminder) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        guard let month = calendar.dateComponents([.year, .month], from: now).month,
              let year = calendar.dateComponents([.year], from: now).year else { return }
        var ids: [String] = []
        for offset in (-2)...0 {
            if let dueDate = calendar.date(from: DateComponents(year: year, month: month, day: reminder.paymentDay + offset)) {
                ids.append(notificationID(for: reminder, date: dueDate))
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    private func notificationID(for reminder: PaymentReminder, date: Date) -> String {
        return "reminder_\(reminder.id.uuidString)_\(date.timeIntervalSince1970)"
    }
} 