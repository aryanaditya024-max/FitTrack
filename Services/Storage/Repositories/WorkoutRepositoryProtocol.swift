import Foundation

public protocol WorkoutRepositoryProtocol: Sendable {
    func fetchWorkouts(includeDeleted: Bool) async throws -> [Workout]
    func fetchWorkout(byId id: UUID) async throws -> Workout?
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [Workout]
    func saveWorkout(_ workout: Workout) async throws
    func softDeleteWorkout(id: UUID) async throws
    func hardDeleteWorkout(id: UUID) async throws
    func updateSyncStatus(id: UUID, status: SyncStatus) async throws
}
