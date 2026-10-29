import Foundation
import UserNotifications

public protocol NotificationServiceProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleDailyReminder(at dateComponents: DateComponents) async throws
    func scheduleWeeklyReminder(weekday: Int, at dateComponents: DateComponents) async throws
    func cancelAllReminders() async
    func areNotificationsEnabled() async -> Bool
}
