import Foundation

public protocol SupabaseDataServiceProtocol: Sendable {
    func upsertWorkout(_ workout: RemoteWorkout) async throws
    func upsertGoal(_ goal: RemoteGoal) async throws
    func fetchWorkoutsUpdatedSince(_ date: Date) async throws -> [RemoteWorkout]
    func fetchGoalsUpdatedSince(_ date: Date) async throws -> [RemoteGoal]
    func uploadDailyMetricSummary(_ metric: RemoteDailyMetric) async throws
}
