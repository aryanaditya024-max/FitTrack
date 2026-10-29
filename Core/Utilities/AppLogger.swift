import Foundation
import os

public enum AppLogger {
    private static let subsystem = "com.fittrack.FitTrack"
    
    public static let health = Logger(subsystem: subsystem, category: "HealthKit")
    public static let storage = Logger(subsystem: subsystem, category: "CoreData")
    public static let sync = Logger(subsystem: subsystem, category: "CloudSync")
    public static let ui = Logger(subsystem: subsystem, category: "Presentation")
}
