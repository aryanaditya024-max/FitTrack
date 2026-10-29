import Foundation
import UserNotifications

public final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {
    
    public static let shared = NotificationService()
    
    private let center: UNUserNotificationCenter
    
    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    public func requestAuthorization() async throws -> Bool {
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    public func areNotificationsEnabled() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    public func scheduleDailyReminder(at dateComponents: DateComponents) async throws {
        // Remove existing daily reminder
        center.removePendingNotificationRequests(withIdentifiers: ["fittrack.daily.reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Move! 🏃"
        content.body = "Check your daily steps and close your activity rings before the day ends."
        content.sound = .default
        
        var matchingComponents = DateComponents()
        matchingComponents.hour = dateComponents.hour ?? 20
        matchingComponents.minute = dateComponents.minute ?? 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: matchingComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "fittrack.daily.reminder", content: content, trigger: trigger)
        
        try await center.add(request)
    }
    
    public func scheduleWeeklyReminder(weekday: Int = 1, at dateComponents: DateComponents) async throws {
        center.removePendingNotificationRequests(withIdentifiers: ["fittrack.weekly.summary"])
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Fitness Recap 📊"
        content.body = "Your weekly workout report is ready. See how you performed against your fitness goals!"
        content.sound = .default
        
        var matchingComponents = DateComponents()
        matchingComponents.weekday = weekday // Sunday = 1
        matchingComponents.hour = dateComponents.hour ?? 18
        matchingComponents.minute = dateComponents.minute ?? 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: matchingComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "fittrack.weekly.summary", content: content, trigger: trigger)
        
        try await center.add(request)
    }
    
    public func cancelAllReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: [
            "fittrack.daily.reminder",
            "fittrack.weekly.summary"
        ])
    }
}
