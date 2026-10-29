import Foundation

/// Codable Data Transfer Object matching Supabase `daily_sensor_metrics` table.
public struct RemoteDailyMetric: Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let metricDate: String // YYYY-MM-DD
    public let stepCount: Int
    public let distanceMeters: Double
    public let activeEnergyKcal: Double
    public let source: String
    public let createdAt: Date?
    public let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case metricDate = "metric_date"
        case stepCount = "step_count"
        case distanceMeters = "distance_meters"
        case activeEnergyKcal = "active_energy_kcal"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(from domain: DailyMetricSummary, userId: UUID) {
        self.id = UUID()
        self.userId = userId
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.metricDate = formatter.string(from: domain.date)
        
        self.stepCount = Int(domain.stepCount)
        self.distanceMeters = domain.distanceMeters
        self.activeEnergyKcal = domain.activeEnergyKcal
        self.source = domain.source.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
