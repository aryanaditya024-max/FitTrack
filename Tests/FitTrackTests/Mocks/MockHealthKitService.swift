import Foundation
import HealthKit
@testable import FitTrack

public final class MockHealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    
    public var isAvailable: Bool = true
    public var shouldAuthorize: Bool = true
    public var mockStepCount: Double = 8450.0
    public var mockActiveEnergy: Double = 420.0
    public var mockDistance: Double = 5200.0
    public var exportedWorkouts: [Workout] = []
    
    public init() {}
    
    public func isHealthDataAvailable() -> Bool {
        return isAvailable
    }
    
    public func requestAuthorization() async throws -> Bool {
        if shouldAuthorize {
            return true
        } else {
            throw HealthKitError.authorizationDenied
        }
    }
    
    public func fetchDailyStepCount(for date: Date) async throws -> Double {
        return mockStepCount
    }
    
    public func fetchDailyActiveEnergy(for date: Date) async throws -> Double {
        return mockActiveEnergy
    }
    
    public func fetchDailyDistance(for date: Date) async throws -> Double {
        return mockDistance
    }
    
    public func fetchDailySummary(for date: Date) async throws -> DailyMetricSummary {
        return DailyMetricSummary(
            date: Calendar.current.startOfDay(for: date),
            stepCount: mockStepCount,
            activeEnergyKcal: mockActiveEnergy,
            distanceMeters: mockDistance,
            source: .sensorHealthKit
        )
    }
    
    public func fetchDailySummaries(from startDate: Date, to endDate: Date) async throws -> [DailyMetricSummary] {
        let calendar = Calendar.current
        var summaries: [DailyMetricSummary] = []
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        while current <= end {
            summaries.append(
                DailyMetricSummary(
                    date: current,
                    stepCount: mockStepCount,
                    activeEnergyKcal: mockActiveEnergy,
                    distanceMeters: mockDistance,
                    source: .sensorHealthKit
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return summaries
    }
    
    public func exportWorkoutToHealthKit(_ workout: Workout) async throws {
        exportedWorkouts.append(workout)
    }
}
