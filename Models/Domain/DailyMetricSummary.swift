import Foundation

/// Aggregated metrics for a single calendar day, maintaining sensor data segregation.
public struct DailyMetricSummary: Identifiable, Hashable, Codable, Sendable {
    public var id: Date { date }
    public let date: Date
    public var stepCount: Double
    public var activeEnergyKcal: Double
    public var distanceMeters: Double
    public var workoutCount: Int
    public var totalWorkoutDuration: TimeInterval
    public let source: DataSourceType
    
    public init(
        date: Date,
        stepCount: Double = 0,
        activeEnergyKcal: Double = 0,
        distanceMeters: Double = 0,
        workoutCount: Int = 0,
        totalWorkoutDuration: TimeInterval = 0,
        source: DataSourceType = .sensorHealthKit
    ) {
        self.date = date
        self.stepCount = stepCount
        self.activeEnergyKcal = activeEnergyKcal
        self.distanceMeters = distanceMeters
        self.workoutCount = workoutCount
        self.totalWorkoutDuration = totalWorkoutDuration
        self.source = source
    }
    
    public func formattedDistance(inImperial: Bool = false) -> String {
        if inImperial {
            let miles = distanceMeters / 1609.344
            return String(format: "%.2f mi", miles)
        } else {
            let km = distanceMeters / 1000.0
            return String(format: "%.2f km", km)
        }
    }
}
