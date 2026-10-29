import Foundation

public enum AppConstants {
    
    public enum Defaults {
        public static let dailyStepGoal: Double = 10000.0
        public static let dailyActiveEnergyGoal: Double = 500.0 // kcal
        public static let dailyDistanceGoal: Double = 5000.0 // meters
        public static let weeklyWorkoutDurationGoal: Double = 9000.0 // 150 minutes in seconds
    }
    
    public enum Sync {
        public static let maxRetryCount: Int16 = 5
        public static let batchLimit: Int = 50
        public static let baseBackoffSeconds: Double = 1.0
    }
    
    public enum NotificationIdentifiers {
        public static let dailyReminder = "fittrack.daily.reminder"
        public static let weeklySummary = "fittrack.weekly.summary"
    }
}
