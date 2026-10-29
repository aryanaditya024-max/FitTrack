import Foundation

/// Supported metric types for fitness goals.
public enum GoalMetricType: String, Codable, CaseIterable, Sendable {
    case steps = "steps"
    case activeEnergy = "active_energy"
    case distance = "distance" // in meters
    case workoutDuration = "workout_duration" // in seconds
    
    public var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Calories"
        case .distance: return "Distance"
        case .workoutDuration: return "Exercise Time"
        }
    }
    
    public var defaultUnit: String {
        switch self {
        case .steps: return "steps"
        case .activeEnergy: return "kcal"
        case .distance: return "km"
        case .workoutDuration: return "min"
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeEnergy: return "flame.fill"
        case .distance: return "location.fill"
        case .workoutDuration: return "clock.fill"
        }
    }
}

/// Goal period frequency.
public enum GoalFrequency: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    
    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

/// Pure Swift domain model representing a fitness goal. Decoupled from Core Data.
public struct FitnessGoal: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var userId: String?
    public var metricType: GoalMetricType
    public var targetValue: Double
    public var frequency: GoalFrequency
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var isDeleted: Bool
    public var syncStatus: SyncStatus
    public var version: Int64
    
    public init(
        id: UUID = UUID(),
        userId: String? = nil,
        metricType: GoalMetricType,
        targetValue: Double,
        frequency: GoalFrequency = .daily,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        syncStatus: SyncStatus = .pendingSync,
        version: Int64 = 1
    ) {
        self.id = id
        self.userId = userId
        self.metricType = metricType
        self.targetValue = targetValue
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.syncStatus = syncStatus
        self.version = version
    }
    
    /// Calculates progress percentage between 0.0 and 1.0 (or greater if exceeded)
    public func progress(currentValue: Double) -> Double {
        guard targetValue > 0 else { return 0 }
        return currentValue / targetValue
    }
    
    /// Formatted representation of target value
    public func formattedTarget(inImperial: Bool = false) -> String {
        switch metricType {
        case .steps:
            return "\(Int(targetValue)) steps"
        case .activeEnergy:
            return "\(Int(targetValue)) kcal"
        case .distance:
            if inImperial {
                let miles = targetValue / 1609.344
                return String(format: "%.1f mi", miles)
            } else {
                let km = targetValue / 1000.0
                return String(format: "%.1f km", km)
            }
        case .workoutDuration:
            let minutes = Int(targetValue / 60)
            return "\(minutes) min"
        }
    }
}
