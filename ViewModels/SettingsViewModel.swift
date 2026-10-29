import Foundation
import Combine

@MainActor
public final class SettingsViewModel: ObservableObject {
    
    @Published public var isImperialUnits: Bool {
        didSet {
            UserDefaults.standard.set(isImperialUnits, forKey: "fittrack.units.isImperial")
        }
    }
    
    @Published public var dailyRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyRemindersEnabled, forKey: "fittrack.reminders.enabled")
            Task {
                await updateReminderSchedule()
            }
        }
    }
    
    @Published public var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "fittrack.reminders.time")
            Task {
                await updateReminderSchedule()
            }
        }
    }
    
    @Published public var cloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(cloudSyncEnabled, forKey: "fittrack.sync.enabled")
        }
    }
    
    private let notificationService: NotificationServiceProtocol
    
    public init(notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.notificationService = notificationService
        
        self.isImperialUnits = UserDefaults.standard.bool(forKey: "fittrack.units.isImperial")
        self.dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "fittrack.reminders.enabled")
        self.cloudSyncEnabled = UserDefaults.standard.bool(forKey: "fittrack.sync.enabled")
        
        let savedTimestamp = UserDefaults.standard.double(forKey: "fittrack.reminders.time")
        if savedTimestamp > 0 {
            self.reminderTime = Date(timeIntervalSince1970: savedTimestamp)
        } else {
            // Default 8:00 PM
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }
    
    public func updateReminderSchedule() async {
        if dailyRemindersEnabled {
            let granted = (try? await notificationService.requestAuthorization()) ?? false
            if granted {
                let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                try? await notificationService.scheduleDailyReminder(at: components)
                try? await notificationService.scheduleWeeklyReminder(weekday: 1, at: components)
            }
        } else {
            await notificationService.cancelAllReminders()
        }
    }
}
