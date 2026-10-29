import Foundation

/// Codable Data Transfer Object matching Supabase PostgreSQL `fitness_goals` table.
public struct RemoteGoal: Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let metricType: String
    public let targetValue: Double
    public let frequency: String
    public let startDate: Date
    public let endDate: Date?
    public let isActive: Bool
    public let isDeleted: Bool
    public let version: Int64
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case metricType = "metric_type"
        case targetValue = "target_value"
        case frequency
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case isDeleted = "is_deleted"
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(from domain: FitnessGoal, userId: UUID) {
        self.id = domain.id
        self.userId = userId
        self.metricType = domain.metricType.rawValue
        self.targetValue = domain.targetValue
        self.frequency = domain.frequency.rawValue
        self.startDate = domain.startDate
        self.endDate = domain.endDate
        self.isActive = domain.isActive
        self.isDeleted = domain.isDeleted
        self.version = domain.version
        self.createdAt = domain.createdAt
        self.updatedAt = domain.updatedAt
    }
    
    public func toDomain() -> FitnessGoal {
        let metric = GoalMetricType(rawValue: metricType) ?? .steps
        let freq = GoalFrequency(rawValue: frequency) ?? .daily
        
        return FitnessGoal(
            id: id,
            userId: userId.uuidString,
            metricType: metric,
            targetValue: targetValue,
            frequency: freq,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            syncStatus: .synced,
            version: version
        )
    }
}
