import Foundation

public protocol GoalRepositoryProtocol: Sendable {
    func fetchGoals(includeDeleted: Bool) async throws -> [FitnessGoal]
    func fetchActiveGoals() async throws -> [FitnessGoal]
    func fetchGoal(byId id: UUID) async throws -> FitnessGoal?
    func saveGoal(_ goal: FitnessGoal) async throws
    func softDeleteGoal(id: UUID) async throws
    func hardDeleteGoal(id: UUID) async throws
    func updateSyncStatus(id: UUID, status: SyncStatus) async throws
}
