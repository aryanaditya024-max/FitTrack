import Foundation
import Supabase

public final class SupabaseDataService: SupabaseDataServiceProtocol, @unchecked Sendable {
    
    public static let shared = SupabaseDataService()
    
    private let clientManager: SupabaseClientManager
    
    // In-memory backing store for local testing/simulation when live credentials are not set
    private var simulatedRemoteWorkouts: [UUID: RemoteWorkout] = [:]
    private var simulatedRemoteGoals: [UUID: RemoteGoal] = [:]
    
    public init(clientManager: SupabaseClientManager = .shared) {
        self.clientManager = clientManager
    }
    
    public func upsertWorkout(_ workout: RemoteWorkout) async throws {
        if !AppEnvironment.isConfigured {
            simulatedRemoteWorkouts[workout.id] = workout
            return
        }
        
        try await clientManager.client
            .from("workouts")
            .upsert(workout, onConflict: "id")
            .execute()
    }
    
    public func upsertGoal(_ goal: RemoteGoal) async throws {
        if !AppEnvironment.isConfigured {
            simulatedRemoteGoals[goal.id] = goal
            return
        }
        
        try await clientManager.client
            .from("fitness_goals")
            .upsert(goal, onConflict: "id")
            .execute()
    }
    
    public func fetchWorkoutsUpdatedSince(_ date: Date) async throws -> [RemoteWorkout] {
        if !AppEnvironment.isConfigured {
            return simulatedRemoteWorkouts.values.filter { $0.updatedAt > date }
        }
        
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        
        let response: [RemoteWorkout] = try await clientManager.client
            .from("workouts")
            .select()
            .gt("updated_at", value: dateString)
            .execute()
            .value
        
        return response
    }
    
    public func fetchGoalsUpdatedSince(_ date: Date) async throws -> [RemoteGoal] {
        if !AppEnvironment.isConfigured {
            return simulatedRemoteGoals.values.filter { $0.updatedAt > date }
        }
        
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: date)
        
        let response: [RemoteGoal] = try await clientManager.client
            .from("fitness_goals")
            .select()
            .gt("updated_at", value: dateString)
            .execute()
            .value
        
        return response
    }
    
    public func uploadDailyMetricSummary(_ metric: RemoteDailyMetric) async throws {
        if !AppEnvironment.isConfigured {
            return
        }
        
        try await clientManager.client
            .from("daily_sensor_metrics")
            .upsert(metric, onConflict: "user_id,metric_date")
            .execute()
    }
}
