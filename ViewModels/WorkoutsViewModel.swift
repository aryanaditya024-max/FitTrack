import Foundation
import Combine

@MainActor
public final class WorkoutsViewModel: ObservableObject {
    
    @Published public var workouts: [Workout] = []
    @Published public var selectedActivityFilter: ActivityType? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let repository: WorkoutRepositoryProtocol
    
    public init(repository: WorkoutRepositoryProtocol = LocalWorkoutRepository()) {
        self.repository = repository
    }
    
    public var filteredWorkouts: [Workout] {
        guard let filter = selectedActivityFilter else {
            return workouts
        }
        return workouts.filter { $0.activityType == filter }
    }
    
    public func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        do {
            self.workouts = try await repository.fetchWorkouts(includeDeleted: false)
        } catch {
            self.errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func deleteWorkout(id: UUID) async {
        do {
            try await repository.softDeleteWorkout(id: id)
            self.workouts.removeAll { $0.id == id }
        } catch {
            self.errorMessage = "Failed to delete workout: \(error.localizedDescription)"
        }
    }
}
