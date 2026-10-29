import Foundation
import HealthKit

public protocol HealthKitServiceProtocol: Sendable {
    func isHealthDataAvailable() -> Bool
    func requestAuthorization() async throws -> Bool
    func fetchDailyStepCount(for date: Date) async throws -> Double
    func fetchDailyActiveEnergy(for date: Date) async throws -> Double
    func fetchDailyDistance(for date: Date) async throws -> Double
    func fetchDailySummary(for date: Date) async throws -> DailyMetricSummary
    func fetchDailySummaries(from startDate: Date, to endDate: Date) async throws -> [DailyMetricSummary]
    func exportWorkoutToHealthKit(_ workout: Workout) async throws
}
