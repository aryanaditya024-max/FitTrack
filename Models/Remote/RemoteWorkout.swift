import Foundation

/// Codable Data Transfer Object matching Supabase PostgreSQL `workouts` table.
public struct RemoteWorkout: Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let activityType: String
    public let startDate: Date
    public let endDate: Date
    public let duration: Double
    public let distance: Double
    public let caloriesBurned: Double
    public let source: String
    public let isDeleted: Bool
    public let version: Int64
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case activityType = "activity_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case duration
        case distance
        case caloriesBurned = "calories_burned"
        case source
        case isDeleted = "is_deleted"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(from domain: Workout, userId: UUID) {
        self.id = domain.id
        self.userId = userId
        self.title = domain.title
        self.activityType = domain.activityType.rawValue
        self.startDate = domain.startDate
        self.endDate = domain.endDate
        self.duration = domain.duration
        self.distance = domain.distance
        self.caloriesBurned = domain.caloriesBurned
        self.source = domain.source.rawValue
        self.isDeleted = domain.isDeleted
        self.version = domain.version
        self.createdAt = domain.createdAt
        self.updatedAt = domain.updatedAt
    }
    
    public func toDomain() -> Workout {
        let activity = ActivityType(rawValue: activityType) ?? .other
        let src = DataSourceType(rawValue: source) ?? .manualEntry
        
        return Workout(
            id: id,
            userId: userId.uuidString,
            title: title,
            activityType: activity,
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            distance: distance,
            caloriesBurned: caloriesBurned,
            source: src,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            syncStatus: .synced,
            version: version
        )
    }
}
