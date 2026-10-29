import Foundation
import Combine

@MainActor
public final class GoalsViewModel: ObservableObject {
    
    @Published public var dailyGoals: [FitnessGoal] = []
    @Published public var weeklyGoals: [FitnessGoal] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let repository: GoalRepositoryProtocol
    
    public init(repository: GoalRepositoryProtocol = LocalGoalRepository()) {
        self.repository = repository
    }
    
    public func loadGoals() async {
        isLoading = true
        errorMessage = nil
        do {
            let allGoals = try await repository.fetchGoals(includeDeleted: false)
            self.dailyGoals = allGoals.filter { $0.frequency == .daily }
            self.weeklyGoals = allGoals.filter { $0.frequency == .weekly }
        } catch {
            self.errorMessage = "Failed to load goals: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func saveGoal(
        id: UUID? = nil,
        metricType: GoalMetricType,
        targetValue: Double,
        frequency: GoalFrequency
    ) async -> Bool {
        let goal = FitnessGoal(
            id: id ?? UUID(),
            metricType: metricType,
            targetValue: targetValue,
            frequency: frequency,
            isActive: true
        )
        
        do {
            try await repository.saveGoal(goal)
            await loadGoals()
            return true
        } catch {
            self.errorMessage = "Failed to save goal: \(error.localizedDescription)"
            return false
        }
    }
    
    public func toggleGoalActive(goal: FitnessGoal) async {
        var updated = goal
        updated.isActive.toggle()
        try? await repository.saveGoal(updated)
        await loadGoals()
    }
    
    public func deleteGoal(id: UUID) async {
        do {
            try await repository.softDeleteGoal(id: id)
            await loadGoals()
        } catch {
            self.errorMessage = "Failed to delete goal: \(error.localizedDescription)"
        }
    }
}
