import Foundation

/// Supported workout activity types with UI symbols and metadata.
public enum ActivityType: String, Codable, CaseIterable, Sendable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case hiit = "hiit"
    case strength = "strength"
    case yoga = "yoga"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiit: return "HIIT"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga"
        case .other: return "Other"
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .hiit: return "flame.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.mind.and.body"
        case .other: return "figure.mixed.cardio"
        }
    }
}

/// Pure Swift domain model for a recorded workout. Decoupled from Core Data.
public struct Workout: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var userId: String?
    public var title: String
    public var activityType: ActivityType
    public var startDate: Date
    public var endDate: Date
    public var duration: TimeInterval
    public var distance: Double // in meters
    public var caloriesBurned: Double // in kcal
    public var source: DataSourceType
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool
    public var syncStatus: SyncStatus
    public var version: Int64
    
    public init(
        id: UUID = UUID(),
        userId: String? = nil,
        title: String,
        activityType: ActivityType,
        startDate: Date,
        endDate: Date? = nil,
        duration: TimeInterval? = nil,
        distance: Double = 0.0,
        caloriesBurned: Double = 0.0,
        source: DataSourceType = .manualEntry,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        syncStatus: SyncStatus = .pendingSync,
        version: Int64 = 1
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.activityType = activityType
        self.startDate = startDate
        
        let calculatedEnd = endDate ?? startDate.addingTimeInterval(duration ?? 1800)
        self.endDate = calculatedEnd
        self.duration = duration ?? max(0, calculatedEnd.timeIntervalSince(startDate))
        self.distance = distance
        self.caloriesBurned = caloriesBurned
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.syncStatus = syncStatus
        self.version = version
    }
    
    // MARK: - Formatted Helpers
    
    public var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
    
    public func formattedDistance(inImperial: Bool = false) -> String {
        if inImperial {
            let miles = distance / 1609.344
            return String(format: "%.2f mi", miles)
        } else {
            let kilometers = distance / 1000.0
            return String(format: "%.2f km", kilometers)
        }
    }
    
    public var formattedCalories: String {
        return String(format: "%.0f kcal", caloriesBurned)
    }
}
